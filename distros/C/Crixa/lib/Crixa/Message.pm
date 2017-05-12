package Crixa::Message;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.13';

use Moose;

use Math::Int64 0.34;
use Moose::Util::TypeConstraints;

has channel => (
    isa      => 'Crixa::Channel',
    is       => 'ro',
    required => 1,
);

has body => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

{
    my @properties = qw(
        content_type
        content_encoding
        correlation_id
        reply_to
        expiration
        message_id
        type
        user_id
        app_id
        priority
        delivery_mode
        timestamp
        headers
    );

    has _properties => (
        traits   => ['Hash'],
        is       => 'bare',
        isa      => 'HashRef',
        init_arg => 'props',
        required => 1,
        handles  => {
            map { ( $_ => [ 'get', $_ ], 'has_' . $_ => [ 'exists', $_ ], ) }
                @properties
        },
    );
}

has redelivered => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has routing_key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has exchange => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# This allows both standard integers and integer objects (e.g., Math::UInt64)
# as long as they stringify correctly.
my $non_negative_int = subtype(
    as 'Defined',
    where {},
    inline_as {
        $_[0]->parent()->_inline_check( $_[1] )
            . " && $_[1]  =~ /^[0-9]+\\z/ ";
    }
);

has delivery_tag => (
    is       => 'ro',
    isa      => $non_negative_int,
    required => 1,
);

has message_count => (
    is        => 'ro',
    isa       => 'Int',
    predicate => '_has_message_count',
);

has consumer_tag => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_consumer_tag',
);

sub BUILD {
    my $self = shift;

    die 'A Crixa::Message must have a message_count or consumer_tag'
        unless $self->_has_message_count() || $self->_has_consumer_tag();

    return;
}

sub ack {
    my $self = shift;
    $self->channel->ack( $self->delivery_tag );
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A Crixa Message

__END__

=pod

=head1 NAME

Crixa::Message - A Crixa Message

=head1 VERSION

version 0.13

=head1 DESCRIPTION

This class represents a single queue. With RabbitMQ, messages are published to
exchanges, which then routes the message to one or more queues. You then
consume those messages from the queue.

=encoding UTF-8

=head1 METHODS

This class provides the following methods:

=head2 $message->ack

This send an acknowledgement for the message on the channel that was used to
receive the message.

=head2 $message->body

This returns the message's body. If the message does not have any
content-encoding set _or_ the message contains an encoding with the string
"utf-8" (case insensitive), then the message is returned as character
data. Otherwise it is returned as binary data.

=head2 Property methods

There are a number of properties that can be associated with a message. This
class provides reader and predicate methods for all properties of the form C<<
$message->foo >> and C<< $message->has_foo >>. None of the properties are
required.

The properties supported are:

=over 4

=item * content_type

=item * content_encoding

=item * correlation_id

=item * reply_to

=item * expiration

=item * message_id

=item * type

=item * user_id

=item * app_id

=item * priority

=item * delivery_mode

=item * timestamp

=item * headers

=back

See the C<publish> method in the L<Crixa::Exchange> docs for more details.

=head2 $message->redelivered

A boolean indicating whether or not the message has already been delivered at
least once. RabbitMQ guarantees that each message will be delivered I<at least
once>, and it is not uncommon for a message to be redelivered before the first
consumer to receive it has had a chance to acknowledge it.

=head2 $message->message_count

The number of messages left in the queue at the time this message was
delivered.

Note that this is only set for messages which are not received via the C<<
Crixa::Queue->consume() >> method.

=head2 $message->routing_key

The routing path on which the message was received.

=head2 $message->exchange

The exchange to which this message was published

=head2 $message->delivery_tag

The delivery tag for a given message. This is used when the C<<
$message->ack() >> method is called.

=head2 $message->consumer_tag

The tag for the consumer associated with the message, if one exists.

Note that this is only set for messages which are received via the C<<
Crixa::Queue->consume() >> method.

=head2 Crixa::Message->new(...)

There is no reason to call this method directly. It will be called by a
L<Crixa::Queue> object to inflate messages into objects.

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
