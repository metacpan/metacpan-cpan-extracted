package Broker::Async::Worker;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( blessed weaken );

=head1 NAME

Broker::Async::Worker

=head1 DESCRIPTION

Used by L<Broker::Async> for tracking the state of asynchronous work.

=cut

our $VERSION = "0.0.6"; # __VERSION__

=head1 ATTRIBUTES

=head2 code

The code reference used to start the work.
This will be invoked with the arguments passed to C<do>.

Must return a L<Future> subclass.

=head2 concurrency

The number of concurrent tasks a worker can execute.
Do'ing more tasks than this limit is a fatal error.

Defaults to 1.

=cut

use Class::Tiny qw( code ), {
    concurrency => sub { 1 },
    futures     => sub { +{} },
    available   => sub { shift->concurrency },
};

=head1 METHODS

=head2 new

    my $worker = Broker::Async::Worker->new(
        code        => sub { ... },
        concurrency => $max,
    );

=head2 available

Indicates whether the worker is available to C<do> tasks.
It is a fatal error to invoke C<do> when this is false.

=head2 do

    my $future = $worker->do($task);

Invokes the code attribute with the given arguments.
Returns a future that will be resolved when the work is done.

=cut

sub active {
    my ($self) = @_;
    return values %{ $self->futures };
}

sub BUILD {
    my ($self) = @_;
    for my $name (qw( code )) {
        croak "$name attribute required" unless defined $self->$name;
    }
}

sub do {
    weaken(my $self = shift);
    my (@args) = @_;
    if (not( $self->available )) {
        croak "worker $self is not available for work";
    }

    my $f = $self->code->(@args);
    if (not( blessed($f) and $f->isa('Future') )) {
        croak "code for worker $self did not return a Future: returned $f";
    }
    $self->available( $self->available - 1 );

    return $self->futures->{$f} = $f->on_ready(sub{
        delete $self->futures->{$f};
        $self->available( $self->available + 1 );
    });
}

=head1 AUTHOR

Mark Flickinger E<lt>maf@cpan.orgE<gt>

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut


1;
