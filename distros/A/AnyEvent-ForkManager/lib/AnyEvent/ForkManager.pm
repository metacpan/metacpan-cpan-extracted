package AnyEvent::ForkManager;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.07';

use AnyEvent;
use Scalar::Util qw/weaken/;
use POSIX qw/WNOHANG/;
use Time::HiRes ();

use Class::Accessor::Lite 0.04 (
    ro  => [
        qw/max_workers manager_pid/,
    ],
    rw  => [
        qw/on_start on_finish on_error on_enqueue on_dequeue on_working_max/,
        qw/process_queue running_worker process_cb wait_async/,
    ],
);

sub default_max_workers { 10 }

sub new {
    my $class = shift;
    my $arg  = (@_ == 1) ? +shift : +{ @_ };
    $arg->{max_workers} ||= $class->default_max_workers;

    bless(+{
        %$arg,
        manager_pid => $$,
    } => $class)->init;
}

sub init {
    my $self = shift;

    $self->process_queue([]);
    $self->running_worker(+{});
    $self->process_cb(+{});

    return $self;
}

sub is_child { shift->manager_pid != $$ }
sub is_working_max {
    my $self = shift;

    $self->num_workers >= $self->max_workers;
}

sub num_workers {
    my $self = shift;
    return scalar keys %{ $self->running_worker };
}

sub num_queues {
    my $self = shift;
    return scalar @{ $self->process_queue };
}

sub start {
    my $self = shift;
    my $arg  = (@_ == 1) ? +shift : +{ @_ };

    die "\$fork_manager->start() should be called within the manager process\n"
        if $self->is_child;

    if ($self->is_working_max) {## child working max
        $self->_run_cb('on_working_max' => @{ $arg->{args} });
        $self->enqueue($arg);
        return;
    }
    else {## create child process
        my $pid = fork;

        if (not(defined $pid)) {
            $self->_run_cb('on_error' => @{ $arg->{args} });
            return;
        }
        elsif ($pid) {
            # parent
            $self->_run_cb('on_start' => $pid, @{ $arg->{args} });
            $self->process_cb->{$pid}     = $self->_create_callback(@{ $arg->{args} });
            $self->running_worker->{$pid} = AnyEvent->child(
                pid => $pid,
                cb  => $self->process_cb->{$pid},
            );

            # delete worker watcher if already finished child process.
            delete $self->running_worker->{$pid} unless exists $self->process_cb->{$pid};

            return $pid;
        }
        else {
            # child
            $arg->{cb}->($self, @{ $arg->{args} });
            $self->finish;
        }
    }
}

sub _create_callback {
    my($self, @args) = @_;

    weaken($self);
    return sub {
        my ($pid, $status) = @_;
        delete $self->running_worker->{$pid};
        delete $self->process_cb->{$pid};
        $self->_run_cb('on_finish' => $pid, $status, @args);

        if ($self->num_queues) {
            ## dequeue
            $self->dequeue;
        }
    };
}

sub finish {
    my ($self, $exit_code) = @_;
    die "\$fork_manager->finish() shouln't be called within the manager process\n"
        unless $self->is_child;

    exit($exit_code || 0);
}

sub enqueue {
    my($self, $arg) = @_;

    $self->_run_cb('on_enqueue' => @{ $arg->{args} });
    push @{ $self->process_queue } => $arg;
}

sub dequeue {
    my $self = shift;

    until ($self->is_working_max) {
        last unless @{ $self->process_queue };

        # dequeue
        if (my $arg = shift @{ $self->process_queue }) {
            $self->_run_cb('on_dequeue' => @{ $arg->{args} });
            $self->start($arg);
        }
    }
}

sub signal_all_children {
    my ($self, $sig) = @_;
    foreach my $pid (sort keys %{ $self->running_worker }) {
        kill $sig, $pid;
    }
}

sub wait_all_children {
    my $self = shift;
    my $arg  = (@_ == 1) ? +shift : +{ @_ };

    my $cb = $arg->{cb};
    if ($arg->{blocking}) {
        $self->_wait_all_children_with_blocking;
        $self->$cb;
    }
    else {
        die 'cannot call.' if $self->wait_async;

        my $super = $self->on_finish;

        weaken($self);
        $self->on_finish(
            sub {
                $super->(@_);
                if ($self->num_workers == 0 and $self->num_queues == 0) {
                    $self->$cb;
                    $self->on_finish($super);
                    $self->wait_async(0);
                }
            }
        );

        $self->wait_async(1);
    }
}

sub _run_cb {
    my $self = shift;
    my $name = shift;

    my $cb = $self->$name();
    if ($cb) {
        $self->$cb(@_);
    }
}

our $WAIT_INTERVAL = 0.1 * 1000 * 1000;
sub _wait_all_children_with_blocking {
    my $self = shift;

    until ($self->num_workers == 0 and $self->num_queues == 0) {
        my($pid, $status) = _wait_with_status(-1, WNOHANG);
        if ($pid and exists $self->running_worker->{$pid}) {
            $self->process_cb->{$pid}->($pid, $status);
        }
    }
    continue {
        # retry interval
        Time::HiRes::usleep( $WAIT_INTERVAL );
    }
}

# function
sub _wait_with_status {## blocking
    my($waitpid, $option) = @_;

    use vmsish 'status';
    local $?;

    my $pid = waitpid($waitpid, $option);
    return ($pid, $?);
}

1;
__END__

=for stopwords cb

=head1 NAME

AnyEvent::ForkManager - A simple parallel processing fork manager with AnyEvent

=head1 VERSION

This document describes AnyEvent::ForkManager version 0.07.

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::ForkManager;
    use List::Util qw/shuffle/;

    my $MAX_WORKERS = 10;
    my $pm = AnyEvent::ForkManager->new(max_workers => $MAX_WORKERS);

    $pm->on_start(sub {
        my($pm, $pid, $sec) = @_;
        printf "start sleep %2d sec.\n", $sec;
    });
    $pm->on_finish(sub {
        my($pm, $pid, $status, $sec) = @_;
        printf "end   sleep %2d sec.\n", $sec;
    });

    my @sleep_time = shuffle(1 .. 20);
    foreach my $sec (@sleep_time) {
        $pm->start(
            cb => sub {
                my($pm, $sec) = @_;
                sleep $sec;
            },
            args => [$sec]
        );
    }

    my $cv = AnyEvent->condvar;

    # wait with non-blocking
    $pm->wait_all_children(
        cb => sub {
            my($pm) = @_;
            print "end task!\n";
            $cv->send;
        },
    );

    $cv->recv;

=head1 DESCRIPTION

C<AnyEvent::ForkManager> is much like L<Parallel::ForkManager>,
but supports non-blocking interface with L<AnyEvent>.

L<Parallel::ForkManager> is useful but,
it is difficult to use in conjunction with L<AnyEvent>.
Because L<Parallel::ForkManager>'s some methods are blocking the event loop of the L<AnyEvent>.

You can accomplish the same goals without adversely affecting the L<Parallel::ForkManager> to L<AnyEvent::ForkManager> with L<AnyEvent>.
Because L<AnyEvent::ForkManager>'s methods are non-blocking the event loop of the L<AnyEvent>.

=head1 INTERFACE

=head2 Methods

=head3 C<< new >>

This is constructor.

=over 4

=item max_workers

max parallel forking count. (default: 10)

=item on_start

started child process callback.

=item on_finish

finished child process callback.

=item on_error

fork error callback.

=item on_enqueue

If push to start up child process queue, this callback is called.

=item on_dequeue

If shift from start up child process queue, this callback is called.

=item on_working_max

If request to start up child process and process count equal max process count, this callback is called.

=back

=head4 Example

  my $pm = AnyEvent::ForkManager->new(
      max_workers => 2,   ## default 10
      on_finish => sub {  ## optional
          my($pid, $status, @anyargs) = @_;
          ## this callback call when finished child process.(like AnyEvent->child)
      },
      on_error => sub {   ## optional
          my($pm, @anyargs) = @_;
          ## this callback call when fork failed.
      },
  );

=head3 C<< start >>

start child process.

=over 4

=item args

arguments passed to the callback function of the child process.

=item cb

run on child process callback.

=back

=head4 Example

  $pm->start(
      cb => sub {   ## optional
          my($pm, $job_id) = @_;
          ## this callback call in child process.
      },
      args => [$job_id],## this arguments passed to the callback function
  );

=head3 C<< wait_all_children >>

You can call this method to wait for all the processes which have been forked.
This can wait with blocking or wait with non-blocking in event loop of AnyEvent.
B<feature to wait with blocking is ALPHA quality till the version hits v1.0.0. Things might be broken.>

=over 4

=item blocking

If this parameter is true, blocking wait enable. (default: false)
B<feature to wait with blocking is ALPHA quality till the version hits v1.0.0. Things might be broken.>

=item cb

finished all the processes callback.

=back

=head4 Example

  $pm->wait_all_children(
      cb => sub {   ## optional
          my($pm) = @_;
          ## this callback call when finished all child process.
      },
  );

=head3 C<< signal_all_children >>

Sends signal to all worker processes. Only usable from manager process.

=head3 C<< on_error >>

As a new method's argument.

=head3 C<< on_start >>

As a new method's argument.

=head3 C<< on_finish >>

As a new method's argument.

=head3 C<< on_enqueue >>

As a new method's argument.

=head3 C<< on_dequeue >>

As a new method's argument.

=head3 C<< on_working_max >>

As a new method's argument.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<AnyEvent>
L<AnyEvent::Util>
L<Parallel::ForkManager>
L<Parallel::Prefork>

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
