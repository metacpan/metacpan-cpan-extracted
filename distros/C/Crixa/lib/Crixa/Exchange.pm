package Crixa::Exchange;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.13';

use Moose;

with qw(Crixa::HasMQ);

has name => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has channel => (
    isa      => 'Crixa::Channel',
    is       => 'ro',
    required => 1,
);

has exchange_type => (
    isa     => 'Str',
    is      => 'ro',
    default => 'direct',
);

has passive => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has durable => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has auto_delete => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

sub BUILD {
    my $self = shift;
    $self->_mq->exchange_declare(
        $self->channel->id,
        $self->name,
        $self->_props,
    );
}

sub queue {
    my $self = shift;
    my $args = @_ == 1 ? $_[0] : {@_};

    my $routing = delete $args->{routing_keys} // [];
    my $q = $self->channel->queue($args);

    for my $key (@$routing) {
        $q->bind( { exchange => $self->name, routing_key => $key } );
    }

    return $q;
}

sub publish {
    my $self = shift;
    my $args = @_ > 1 ? {@_} : ref $_[0] ? $_[0] : { body => $_[0] };

    my $routing_key = delete $args->{routing_key} // q{};
    my $body = delete $args->{body}
        || confess(
        'You must supply a body when calling the publish() method');
    my $props = delete $args->{props};

    $args->{exchange} = $self->name;

    return $self->_mq->publish(
        $self->channel->id,
        $routing_key,
        $body,
        $args,
        $props,
    );
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete {
    my $self = shift;
    my $args = @_ > 1 ? {@_} : ref $_[0] ? $_[0] : {};

    $self->_mq->exchange_delete( $self->channel->id, $self->name, $args );
}
## use critic

sub _props {
    my $self = shift;

    return { map { $_ => $self->$_() }
            qw( exchange_type passive durable auto_delete ) };
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A Crixa Exchange

__END__

=pod

=head1 NAME

Crixa::Exchange - A Crixa Exchange

=head1 VERSION

version 0.13

=head1 DESCRIPTION

This class represents a single exchange. With RabbitMQ, messages are published
to an exchange. Queues can then connect to exchanges and receive those messages.

=encoding UTF-8

=head1 METHODS

This class provides the following methods:

=head2 Crixa::Exchange->new

You should not call this method directly under normal circumstances. Instead,
you should create an exchange by calling the C<exchange> method on a
L<Crixa::Channel> object. However, you need to know what parameters the
constructor accepts.

=over 4

=item * name => $name

This is a required string. Note that the empty string is acceptable here, as
this is the default exchange name for RabbitMQ.

=item * exchange_type => $type

This is an optional string. It can be any type of exchange supported by
RabbitMQ, including those provided by plugins.

This defaults to "direct".

=item * passive => $bool

If this is true, then the constructor will throw an error B<unless the
exchange already exists>.

This defaults to false.

=item * durable => $bool

If this is true, then the exchange will remain active across server
restarts.

B<This has nothing to do with whether messages are stored! In order to make
sure messages are written to disk, you must declare the I<queue> as durable>

This defaults to false.

=item * auto_delete => $bool

If this is true, then the exchange will be deleted when all queues have
finished using it.

This defaults to true.

=back

=head2 $exchange->publish(...)

This method sends a message to the exchange. It accepts either a hash or
hashref with the following keys:

=over 4

=item * routing_key

This is an optional routing key for the message. If this is not provided then
the empty string is used.

=item * body

This is the message body. This should be a scalar containing any sort of data.

=item * mandatory

If this is true, then if the message cannot be routed to a queue, the server
will return an unroutable message. This defaults to false.

B<Note that as of this writing L<Net::AMQP::RabbitMQ> does not support return
messages from publishing, so this flag is not really useful.>

=item * immediate

If this is true, then if the message cannot be routed immediately, the server
will return an undeliverable message. This defaults to false.

B<Note that as of this writing L<Net::AMQP::RabbitMQ> does not support return
messages from publishing, so this flag is not really useful.>

=item * props

This is an optional hashref containing message metadata:

=over 8

=item * content_type => $ct

This should be a MIME type like "application/json" or "text/plain". This is
exactly like an HTTP Content-Type header.

Note that RabbitMQ doesn't really care about the content of your message. This
is for the benefit of whatever code eventually consumes this message.

=item * content_encoding => $enc

The MIME content encoding of the message. This is exactly like an HTTP
Content-Encoding header.

Note that RabbitMQ doesn't really care about the content of your message. This
is for the benefit of whatever code eventually consumes this message.

=item * message_id => $id

A unique identifier for the message that you create.

=item * correlation_id => $correlation

This is the ID of the message for which the message you're publishing is a
reply to.

=item * reply_to => $reply_to

This is typically used to name the queue to which reply messages should be
sent.

=item * expiration => $expiration

This is the message expiration as a number in milliseconds. If the message
cannot be delivered within that time frame it will be discarded.

If both the queue and the message define an expiration time, the lower of the
two will be used.

=item * type => $type

The message type (not content type) as a string. This could be something like
"order" or "email", etc.

=item * user_id => $user_id

A string identifying the message's sender. If this is provided, then RabbitMQ
requires that this be identical to the username used to connect to RabbitMQ.

=item * app_id => $app_id

This is a string identifying the app that sent the message. For example, you
might used something like "webcrawler" or "rest-api".

=item * delivery_mode => $mode

This can either be 1 or 2. A 1 is "non-persistent" and a 2 is
"persistent". This defines whether or not the message is stored on disk so
that it can be recovered across RabbitMQ server restarts.

Note that even if you set the exchange and queue to be durable, you still must
specify the C<delivery_mode> as persistent in order for it to be saved!

=item * timestamp => $epoch

This is an epoch time indicating when the message was sent.

=item * priority => $priority

This can be a number from 0 to 9, but RabbitMQ ignores this.

=item * headers => { ... }

An arbitrary hashref of headers. This is something like "X-*" headers in
HTTP. You can put anything you want here. This is used when matching messages
to queues via a headers-type exchange.

=back

You are strongly encouraged to use the well-known properties listed above
instead of encoding similar information in the message body or in the
C<headers> property.

=back

B<Note that if you publish a message and there is no queue bound to the
exchange which can receive that message, the message will be discarded. This
means you must create your exchanges and queues I<before> you publish any
messages.>.

=head2 $exchange->queue(...)

This returns a new L<Crixa::Queue> object. This method accepts all of the
arguments that can be passed to the L<Crixa::Queue> constructor, either as a
hash or hashref. See the L<Crixa::Queue> documentation for more details.

In addition, it also accepts a C<routing_keys> parameter, which should be an
arrayref of strings. If these are provided, then the queue is bound to the
exchange with each string in the arrayref as a routing key.

This is a convenient way of declaring and binding a queue all at once.

=head2 $exchange->delete(...)

This deletes the exchange. It accepts either a hash or hashref with the
following keys:

=over 4

=item * if_unused => $bool

If this is true, then the exchange is only deleted if it has no queue
bindings. This defaults to true.

=item * no_wait => $bool

If this is true, then the method returns immediately without getting
confirmation from the server. This defaults to false.

=back

=head2 $exchange->name(...)

This returns the exchange name as passed to the constructor.

=head2 $exchange->channel

Returns the L<Crixa::Channel> that this exchange uses.

=head2 $exchange->exchange_type

This returns the exchange type as passed to the constructor or set by a
default.

=head2 $exchange->passive

This returns the passive flag as passed to the constructor or set by a
default.

=head2 $exchange->durable

This returns the durable flag as passed to the constructor or set by a
default.

=head2 $exchange->auto_delete

This returns the auto-delete flag as passed to the constructor or set by a
default.

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
