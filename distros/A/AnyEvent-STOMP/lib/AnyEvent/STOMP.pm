package AnyEvent::STOMP;

use 5.008;
use common::sense;

use base 'Object::Event';
use Carp qw(croak);
use AnyEvent;
use AnyEvent::Handle;

our $VERSION = 0.7;

=head1 NAME

AnyEvent::STOMP - A lightweight event-driven STOMP client

=head1 SYNOPSIS

 use AnyEvent;
 use AnyEvent::STOMP;

 my $client = AnyEvent::STOMP->connect($host, $port, $ssl, $destination, $ack,
                                       { connect_headers },
                                       { subscribe_headers });

 $client->send($command, $headers, $body);

 # Register interest in new messages
 $client->reg_cb(MESSAGE => sub {
     my (undef, $body, $headers) = @_;
     # Do something with the frame
 });

 # Register interest in any frame received.  Use with caution.
 $client->reg_cb(frame => sub {
     my (undef, $type, $body, $headers) = @_;
     # Do something with the frame
 });

 # Start the event loop
 AnyEvent->condvar->recv;

=cut

=head1 DESCRIPTION

AnyEvent::STOMP is a lightweight event-driven STOMP client.  It's intended
to be run in the context of an event loop driven by AnyEvent.

=head2 Making a connection

 my $client = AnyEvent::STOMP->connect($host, $port, $ssl, $destination, $ack,
                                       { connect_headers },
                                       { subscribe_headers });

Only the first parameter (the hostname) is required.  The remaining optional
arguments are:

=over

=item port

The port number to connect to.  If not specified, defaults to 61612 (if SSL/TLS
is used) or 61613 (if not).

=item ssl

If set to a true value, use SSL/TLS to connect.

=item destination

If defined, subscribe to the specified destination (queue) upon connection.

=item ack

Sets the behavior with respect to STOMP frame acknowledgments.

If this value is 0 or undef, no acknowledgment is required: the server will
consider all sent frames to be delivered, regardless of whether the client has
actually received them.  (This is the default behavior according to the STOMP
protocol.)

If set to C<auto>, the client will automatically acknowledge a frame upon
receipt.

If set to C<manual>, the caller must acknowledge frames manually via the
ack() method.

=item connect_headers

An anonymous hash of headers (key/value pairs) to send in the STOMP CONNECT
frame.

=item subscribe_headers

An anonymous hash of headers (key/value pairs) to send in the STOMP SUBSCRIBE
frame.

=back

=cut

sub connect {
    my $class = shift;
    my ($host, $port, $ssl, $destination, $ack,
        $connect_headers, $subscribe_headers) = @_;

    croak 'No host provided' unless $host;
    croak "ack value must be 0, undef, 'auto' or 'manual'"
        if $ack && $ack ne 'auto' && $ack ne 'manual';

    my $self = $class->SUPER::new;

    $self->{ack} = $ack;

    $port ||= ($ssl ? 61612 : 61613);

    my $connect_cb;
    $self->{handle} = AnyEvent::Handle->new(
        connect => [ $host, $port ],
        tls => $ssl ? 'connect' : undef,
        keepalive => 1,
        on_prepare => sub { $self->event('prepare', @_); },
        on_connect => sub {
            $self->event('connect', @_);
            $self->send_frame('CONNECT', undef, $connect_headers);
            if ($destination) {
                $subscribe_headers->{destination} = $destination;
                $subscribe_headers->{ack} = 'client' if $ack;
                $connect_cb = $self->reg_cb(CONNECTED => sub {
                        $self->{session_id} = $_[2]->{session};
                        $self->send_frame('SUBSCRIBE',
                            undef, $subscribe_headers);
                        undef $connect_cb;
                });
            }
        },
        on_connect_error => sub {
            $self->event('connect_error', $_[1]);
        },
        on_error => sub {
            $self->unreg_cb($connect_cb) if (defined $connect_cb);
            $self->{handle}->destroy;
            $self->event('io_error', $_[2]);
        },
        on_read => sub { $self->_receive_frame },
    );
    return bless($self, $class);
}

=head2 Sending a message

To send a message, just call send() with the body, the destination (queue)
name, and (optionally) any additional headers:

 $client->send($body, $destination, $headers); # headers may be undef

=cut

sub send {
    my $self = shift;
    my ($body, $destination, $headers) = @_;

    croak 'Missing destination' unless defined $destination;

    $headers->{destination} = $destination;
    $self->send_frame('SEND', $body, $headers);
}

=head2 Sending STOMP frames

You can also send arbitrary STOMP frames:

 $client->send_frame($command, $body, $headers); # headers may be undef

See the STOMP protocol documentation for more details on valid commands and
headers.

=head3 Content Length

The C<content-length> header is special because it is sometimes used to
indicate the length of the body but also the JMS type of the message in
ActiveMQ as per L<http://activemq.apache.org/stomp.html>.

If you do not supply a C<content-length> header, following the protocol
recommendations, a C<content-length> header will be added if the frame has a
body.

If you do supply a numerical C<content-length> header, it will be used as
is. Warning: this may give unexpected results if the supplied value does not
match the body length. Use only with caution!

Finally, if you supply an empty string as the C<content-length> header, it
will not be sent, even if the frame has a body. This can be used to mark a
message as being a TextMessage for ActiveMQ. Here is an example of this:

 $client->send_frame($command, $body, { 'content-length' => '' } );

=cut

sub send_frame {
    my $self = shift;
    my ($command, $body, $headers) = @_;

    croak 'Missing command' unless $command;

    my $tmp = $headers->{'content-length'};
    if (!defined $tmp) {
        $headers->{'content-length'} = length $body;
    } elsif ($tmp eq '') {
        delete $headers->{'content-length'};
    }

    my $frame = sprintf("%s\n%s\n%s\000",
                        $command,
                        join('', map { "$_:$headers->{$_}\n" } keys %$headers),
                        $body);

    $self->{handle}->push_write($frame);
}

=head2 Events

Once you've connected, you can register interest in events, most commonly
the receipt of new messages (assuming you've connected as a subscriber).

The typical use is:

 $client->reg_cb($type => $cb->($client, $body, $headers));

In most cases, $type is C<MESSAGE>, but you can also register interest
in any other type of frame (C<RECEIPT>, C<ERROR>, etc.).  (If you register
interest in C<CONNECTED> frames, please do so with a priority of C<after>;
see Object::Event for more details.)

The client object (which can usually be ignored), body and headers (as an
anonymous hash of key-value pairs) will be passed to your callback.

Other events you can register interest in are:

=over

=item prepare => $cb->($client, $handle)

Will be fired after a client socket has been allocated.  See C<on_prepare> in
AnyEvent::Handle for more details.

=item connect => $cb->($client, $handle, $host, $port, $retry->())

Will be fired when the client has successfully connected to the STOMP server.
See C<on_connect> in AnyEvent::Handle for more details.

=item frame => $cb->($client, $type, $body, $headers)

Will be fired whenever any frame is received.

=item connect_error => $cb->($client, $errmsg)

Will be fired if the attempt to connect to the STOMP server fails.  See
C<on_connect_error> in AnyEvent::Handle for more details.

=item io_error => $cb->($client, $errmsg)

Will be fired if an I/O error occurs.  See C<on_error> in AnyEvent::Handle
for more details.

=back

=cut

sub _receive_frame {
    my $self = shift;

    my $command;
    my $headers = {};
    my $body;

    $self->{handle}->unshift_read(regex => qr/\n*([^\n].*?)\n\n/s,
                                  sub {
            my $raw_headers = $_[1];
            if ($raw_headers =~ s/^(.+)\n//) {
                $command = $1;
            }
            foreach my $line (split(/\n/, $raw_headers)) {
                my ($key, $value) = split(/\s*:\s*/, $line, 2);
                $headers->{$key} = $value;
            }
            my @args;
            if (my $content_length = $headers->{'content-length'}) {
                @args = ('chunk' => $content_length + 1);
            } else {
                @args = ('regex' => qr/.*?\000\n*/s);
            }
            $self->{handle}->unshift_read(@args, sub {
                    $body = $_[1];
                    $body =~ s/\000\n*$//;

                    if ($self->{ack} eq 'auto' && defined $headers->{'message-id'}) {
                        $self->send_frame('ACK', undef,
                                          {'message-id' => $headers->{'message-id'}});
                    }

                    $self->event($command, $body, $headers);
                    $self->event('frame', $command, $body, $headers);
            });
    });
}

=head2 Acknowledging frames

You can acknowledge a frame received via the ack() method:

  $client->ack($id, $transaction);

The transaction is optional.

=cut

sub ack {
    my $self = shift;
    my ($id, $transaction) = @_;

    croak 'Missing ID' unless $id;

    my $headers = { 'message-id' => $id };
    $headers->{transaction} = $transaction if defined $transaction;

    $self->send_frame('ACK', undef, $headers);
}

=head2 Closing a session

When done with a session, you need to explicitly call the destroy() method.
It will also send a DISCONNECT message on your behalf before closing.
Attempting to let the object fall out-of scope is not sufficient.

  $client->destroy;

=cut

sub destroy {
	my ($self) = shift;
    $self->send_frame('DISCONNECT') if defined undef $self->{handle};
	undef $self->{handle};
}

=head1 SEE ALSO

AnyEvent, AnyEvent::Handle, Object::Event, STOMP Protocol
L<http://stomp.codehaus.org/Protocol>

=head1 AUTHORS AND CONTRIBUTORS

Fulko.Hew (L<fulko.hew@gmail.com>) is the current maintainer.

Michael S. Fischer (L<michael+cpan@dynamine.net>) wrote the original version.

=head1 COPYRIGHT AND LICENSE

(C) 2014 SITA INC Canada, Inc.
(C) 2010 Yahoo! Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

__END__

# vim:syn=perl:sw=4:ts=4:et:ai
