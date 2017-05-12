package Crixa::Channel;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.13';

use Moose;

use Crixa::Queue;
use Crixa::Exchange;

with qw(Crixa::HasMQ);

has id => ( isa => 'Str', is => 'ro', required => 1 );

sub BUILD { $_[0]->_mq->channel_open( $_[0]->id ); }

sub exchange {
    my $self = shift;
    Crixa::Exchange->new(
        @_,
        channel => $self,
        _mq     => $self->_mq,
    );
}

sub basic_qos {
    my $self = shift;
    my $args = @_ == 1 ? $_[0] : {@_};
    $self->_mq->basic_qos( $self->id, $args );
}

sub queue {
    my $self = shift;
    my $args = @_ == 1 ? shift : {@_};
    $args->{_mq}     = $self->_mq;
    $args->{channel} = $self;
    return Crixa::Queue->new($args);
}

sub ack { $_[0]->_mq->ack( shift->id, @_ ) }

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A Crixa Channel

__END__

=pod

=head1 NAME

Crixa::Channel - A Crixa Channel

=head1 VERSION

version 0.13

=head1 DESCRIPTION

This class represents a channel. A channel is a lot like a socket. You will
probably want to have a unique channel per process or thread for your
application. You may also want to have separate channels for publishing and
consuming messages.

It is safe (and encouraged) to keep the same channel open over a long period
of time for publishing or consuming messages. There is no need to create new
channels on a regular basis.

Also note that message delivery tags are scoped to the channel on which a
message is delivered, and therefore message acks must go back to that same
channel.

Channels are created by calling the C<< Crixa->new_channel >> method.

=encoding UTF-8

=head1 METHODS

This class provides the following methods:

=head2 $channel->exchange(...)

This method creates a new L<Crixa::Exchange> object. Any parameters passed to
this method are passed directly to the L<Crixa::Exchange> constructor, either
as a hash or hashref. See the L<Crixa::Exchange> documentation for more
details.

=head2 $channel->queue(...)

This method creates a new L<Crixa::Queue> object. Any parameters passed to
this method are passed directly to the L<Crixa::Queue> constructor, either as
a hash or hashref. See the L<Crixa::Queue> documentation for more details.

=head2 $channel->basic_qos(...)

This method sets quality of service flags for the channel. This method
takes a hash or hash reference with the following keys:

=over 4

=item * prefetch_count => $count

If this is set, then the channel will fetch C<$count> additional messages to
the client when it is consuming messages, rather than sending them down the
socket one at a time.

=item * prefetch_size => $size

Set the maximum number of I<bytes> that will be prefetched. If both this and
C<prefetch_count> are set then the smaller of the two wins.

=item * global => $bool

If this is true, then the QoS settings apply to all consumers on this
channel. If it is false, then it only applies to new consumers created after
this is set.

In Crixa, a new AMQP consumer is created whenever you call any methods to get
messages on a L<Crixa::Queue> object, so this setting doesn't really matter.

=back

Note that prefetching messages is only done when the queue is created in "no
ack" mode (or "auto ack" if you prefer to think of it that way).

=head2 $channel->ack(...)

This method acknowledges delivery of a message received on this channel.

It accepts two positional arguments. The first is the delivery tag for the
message, which is required. The second is the "multiple" flag. If this is
true, it means that you are acknowledging all messages up to the given
delivery tag. It defaults to false.

=head2 $channel->id

This returns the channel's unique id. This is a positive integer.

=head2 Crixa::Channel->new(...)

Don't call this method directly. Instead, call C<new_channel> on a connected
L<Crixa> object.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2015 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
