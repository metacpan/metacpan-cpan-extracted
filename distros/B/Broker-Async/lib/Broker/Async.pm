package Broker::Async;
use strict;
use warnings;
use Broker::Async::Worker;
use Carp;
use Scalar::Util qw( blessed weaken );

=head1 NAME

Broker::Async - broker tasks for multiple workers

=for html <a href="https://travis-ci.org/mark-5/p5-broker-async"><img src="https://travis-ci.org/mark-5/p5-broker-async.svg?branch=master"></a>

=head1 SYNOPSIS

    my @workers;
    for my $uri (@uris) {
        my $client = SomeClient->new($uri);
        push @workers, sub { $client->request(@_) };
    }

    my $broker = Broker::Async->new(workers => \@workers);
    for my $future (map $broker->do($_), @requests) {
        my $result = $future->get;
        ...
    }

=head1 DESCRIPTION

This module brokers tasks for multiple asynchronous workers. A worker can be any code reference that returns a L<Future>, representing work awaiting completion.

Some common use cases include throttling asynchronous requests to a server, or delegating tasks to a limited number of processes.

=cut

our $VERSION = "0.0.6"; # __VERSION__

=head1 ATTRIBUTES

=head2 workers

An array ref of workers used for handling tasks.
Can be a code reference, a hash ref of L<Broker::Async::Worker> arguments, or a L<Broker::Async::Worker> object.
Every invocation of a worker must return a L<Future> object.

Under the hood, code and hash references are simply used to instantiate a L<Broker::Async::Worker> object.
See L<Broker::Async::Worker> for more documentation about how these parameters are used.

=cut

use Class::Tiny qw( workers ), {
    queue => sub {  [] },
};

=head1 METHODS

=head2 new

    my $broker = Broker::Async->new(
        workers => [ sub { ... }, ... ],
    );

=cut

sub active {
    my ($self) = @_;
    return grep { $_->active } @{ $self->workers };
}

sub available {
    my ($self) = @_;
    return grep { $_->available } @{ $self->workers };
}

sub BUILD {
    my ($self) = @_;
    for my $name (qw( workers )) {
        croak "$name attribute required" unless defined $self->$name;
    }

    my $workers = $self->workers;
    croak "workers attribute must be an array ref: received $workers"
        unless ref($workers) eq 'ARRAY';

    for (my $i = 0; $i < @$workers; $i++) {
        my $worker = $workers->[$i];

        my $type = ref($worker);
        if ($type eq 'CODE') {
            $workers->[$i] = Broker::Async::Worker->new({code => $worker});
        } elsif ($type eq 'HASH') {
            $workers->[$i] = Broker::Async::Worker->new($worker);
        }
    }
}

=head2 do

    my $future = $broker->do(@args);

Queue the invocation of a worker with @args.
@args can be any data structure, and is passed as is to a worker code ref.
Returns a L<Future> object that resolves when the work is done.

There is no guarantee when a worker will be called, that depends on when a worker becomes available.
However, calls are guaranteed to be invoked in the order they are seen by $broker->do.

=cut


sub do {
    my ($self, @args) = @_;

    # enforces consistent order of task execution
    # makes sure current task is only started if nothing else is queued
    $self->process_queue;

    my $future;
    if (my @active_futures = map $_->active, $self->active) {
        # generate future from an existing future
        # see Future::_new_convergent
        my $_future = $active_futures[0];
        ref($_) eq "Future" or $_future = $_, last for @active_futures;

        $future = $_future->new;
        push @{ $self->queue }, {args => \@args, future => $future};
    } elsif (my ($available_worker) = $self->available) {
        # should only be here if there's nothing active and nothing queued
        # so start the task and return it's future
        $future = $self->do_worker($available_worker, @args);
    }

    # start any recently queued tasks, if there are available workers
    $self->process_queue;
    return $future;
}

sub do_worker {
    weaken(my $self = shift);
    my ($worker, @args) = @_;

    return $worker->do(@args)->on_ready(sub{
        # queue next task
        $self->process_queue;
    });
}

sub process_queue {
    weaken(my $self = shift);
    my $queue = $self->queue;

    while (@$queue) {
        my ($worker) = $self->available or last;
        my $task     = shift @$queue;

        $self->do_worker($worker, @{$task->{args}})
             ->on_ready($task->{future});
    }
}

=head1 AUTHOR

Mark Flickinger E<lt>maf@cpan.orgE<gt>

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut

1;
