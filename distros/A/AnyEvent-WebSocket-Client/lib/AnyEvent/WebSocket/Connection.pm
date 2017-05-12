package AnyEvent::WebSocket::Connection;

use strict;
use warnings;
use Moo;
use Protocol::WebSocket::Frame;
use Scalar::Util ();
use Encode ();
use AE;
use AnyEvent::WebSocket::Message;
use PerlX::Maybe qw( maybe provided );
use Carp ();

# ABSTRACT: WebSocket connection for AnyEvent
our $VERSION = '0.38'; # VERSION


has handle => (
  is       => 'ro',
  required => 1,
);


has masked => (
  is      => 'ro',
  default => sub { 0 },
);


has subprotocol => (
  is => 'ro',
);


has max_payload_size => (
  is => 'ro',
);

foreach my $type (qw( each_message next_message finish parse_error ))
{
  has "_${type}_cb" => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [] },
  );
}

foreach my $flag (qw( _is_read_open _is_write_open ))
{
  has $flag => (
    is       => 'rw',
    init_arg => undef,
    default  => sub { 1 },
  );
}

has "_is_finished" => (
  is       => 'rw',
  init_arg => undef,
  default  => sub { 0 },
);

sub BUILD
{
  my $self = shift;
  Scalar::Util::weaken $self;
  
  my @temp_messages = ();
  my $are_callbacks_supposed_to_be_ready = 0;
  
  my $finish = sub {
    my $strong_self = $self; # preserve $self because otherwise $self can be destroyed in the callbacks.
    return if $self->_is_finished;
    eval
    {
      $self->_process_message($_) foreach @temp_messages;
    };
    @temp_messages = ();
    $self->_is_finished(1);
    $self->handle->push_shutdown;
    $self->_is_read_open(0);
    $self->_is_write_open(0);
    $_->($self) for @{ $self->_finish_cb };
  };
  $self->handle->on_error($finish);
  $self->handle->on_eof($finish);

  my $frame = Protocol::WebSocket::Frame->new( maybe max_payload_size => $self->max_payload_size );

  my $read_cb = sub {
    my ($handle) = @_;
    local $@;
    my $strong_self = $self; # preserve $self because otherwise $self can be destroyed in the callbacks
    my $success = eval
    {
      $frame->append($handle->{rbuf});
      while(defined(my $body = $frame->next_bytes))
      {
        next if !$self->_is_read_open; # not 'last' but 'next' in order to consume data in $frame buffer.
        my $message = AnyEvent::WebSocket::Message->new(
          body   => $body,
          opcode => $frame->opcode,
        );
        if($are_callbacks_supposed_to_be_ready)
        {
          $self->_process_message($message);
        }
        else
        {
          push(@temp_messages, $message);
        }
      }
      1; # succeed to parse.
    };
    if(!$success)
    {
      $self->_force_shutdown();
      $_->($self, $@) for @{ $self->_parse_error_cb };
    }
  };


  # Message processing (calling _process_message) is delayed by
  # $are_callbacks_supposed_to_be_ready flag. This is necessary to
  # make sure all received messages are delivered to each_message and
  # next_message callbacks. If there is some data in rbuf, changing
  # the on_read callback makes the callback fire, but there is of
  # course no each_message/next_message callback to receive the
  # message yet. So we put messages to @temp_messages for a
  # while. After the control is returned to the user, who sets up
  # each_message/next_message callbacks, @temp_messages are processed.

  # An alternative approach would be temporarily disabling on_read by
  # $self->handle->on_read(undef). However, this can cause a weird
  # situation in TLS mode, because on_eof can fire even if we don't
  # have any on_read (
  # https://metacpan.org/pod/AnyEvent::Handle#I-get-different-callback-invocations-in-TLS-mode-Why-cant-I-pause-reading
  # )   
  $self->handle->on_read($read_cb);
  my $idle_w; $idle_w = AE::idle sub {
    undef $idle_w;
    if(defined($self))
    {
      my $strong_self = $self;
      $are_callbacks_supposed_to_be_ready = 1;
      local $@;
      my $success = eval
      {
        $self->_process_message($_) foreach @temp_messages;
        1;
      };
      @temp_messages = ();
      if(!$success)
      {
        $self->_force_shutdown();
      }
    }
  };
}

sub _process_message
{
  my ($self, $received_message) = @_;
  return if !$self->_is_read_open;
  
  if($received_message->is_text || $received_message->is_binary)
  {
    $_->($self, $received_message) for @{ $self->_next_message_cb };
    @{ $self->_next_message_cb } = ();
    $_->($self, $received_message) for @{ $self->_each_message_cb };
  }
  elsif($received_message->is_close)
  {
    $self->_is_read_open(0);
    $self->close();
  }
  elsif($received_message->is_ping)
  {
    $self->send(AnyEvent::WebSocket::Message->new(opcode => 10, body => $received_message->body));
  }
}

sub _force_shutdown
{
  my ($self) = @_;
  $self->handle->push_shutdown;
  $self->_is_write_open(0);
  $self->_is_read_open(0);
}


sub send
{
  my($self, $message) = @_;
  my $frame;
  
  return $self if !$self->_is_write_open;
  
  if(ref $message)
  {
    $frame = Protocol::WebSocket::Frame->new(buffer => $message->body, masked => $self->masked, max_payload_size => 0);
    $frame->opcode($message->opcode);
  }
  else
  {
    $frame = Protocol::WebSocket::Frame->new(buffer => $message, masked => $self->masked, max_payload_size => 0);
  }
  $self->handle->push_write($frame->to_bytes);
  $self;
}


sub on
{
  my($self, $event, $cb) = @_;
  
  if($event eq 'next_message')
  {
    push @{ $self->_next_message_cb }, $cb;
  }
  elsif($event eq 'each_message')
  {
    push @{ $self->_each_message_cb }, $cb;
  }
  elsif($event eq 'finish')
  {
    push @{ $self->_finish_cb }, $cb;
  }
  elsif($event eq 'parse_error')
  {
    push @{ $self->_parse_error_cb }, $cb;
  }
  else
  {
    Carp::croak "unrecongized event: $event";
  }
  $self;
}


sub close
{
  my($self, $code, $reason) = @_;

  my $body = pack('n', ($code) ? $code : '1005');

  $body .= Encode::encode 'UTF-8', $reason if defined $reason;

  $self->send(AnyEvent::WebSocket::Message->new(
    opcode => 8,
    body => $body,
  ));
  $self->handle->push_shutdown;
  $self->_is_write_open(0);
  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::WebSocket::Connection - WebSocket connection for AnyEvent

=head1 VERSION

version 0.38

=head1 SYNOPSIS

 # send a message through the websocket...
 $connection->send('a message');
 
 # recieve message from the websocket...
 $connection->on(each_message => sub {
   # $connection is the same connection object
   # $message isa AnyEvent::WebSocket::Message
   my($connection, $message) = @_;
   ...
 });
 
 # handle a closed connection...
 $connection->on(finish => sub {
   # $connection is the same connection object
   my($connection) = @_;
   ...
 });
 
 # close an opened connection
 # (can do this either inside or outside of
 # a callback)
 $connection->close;

(See L<AnyEvent::WebSocket::Client> or L<AnyEvent::WebSocket::Server> on 
how to create a connection)

=head1 DESCRIPTION

This class represents a WebSocket connection with a remote server or a 
client.

If the connection object falls out of scope then the connection will be 
closed gracefully.

This class was created for a client to connect to a server via 
L<AnyEvent::WebSocket::Client>, and was later extended to work on the 
server side via L<AnyEvent::WebSocket::Server>.  Once a WebSocket 
connection is established, the API for both client and server is 
identical.

=head1 ATTRIBUTES

=head2 handle

The underlying L<AnyEvent::Handle> object used for the connection.
WebSocket handshake MUST be already completed using this handle.
You should not use the handle directly after creating L<AnyEvent::WebSocket::Connection> object.

Usually only useful for creating server connections, see below.

=head2 masked

If set to true, it masks outgoing frames. The default is false.

=head2 subprotocol

The subprotocol returned by the server.  If no subprotocol was requested, it
may be C<undef>.

=head2 max_payload_size

The maximum payload size for received frames.  Currently defaults to whatever
L<Protocol::WebSocket> defaults to.

=head1 METHODS

=head2 send

 $connection->send($message);

Send a message to the other side.  C<$message> may either be a string
(in which case a text message will be sent), or an instance of
L<AnyEvent::WebSocket::Message>.

=head2 on

 $connection->on(each_message => $cb);
 $connection->on(each_message => $cb);
 $connection->on(finish => $cb);

Register a callback to a particular event.

For each event C<$connection> is the L<AnyEvent::WebSocket::Connection> and
and C<$message> is an L<AnyEvent::WebSocket::Message> (if available).

=head3 each_message

 $cb->($connection, $message)

Called each time a message is received from the WebSocket.

=head3 next_message

 $cb->($connection, $message)

Called only for the next message received from the WebSocket.

=head3 parse_error

 $cb->($connection, $text_error_message)

Called if there is an error parsing a message sent from the remote end.
After this callback is called, the connection will be closed.
Among other possible errors, this event will trigger if a frame has a
payload which is larger that C<max_payload_size>.

=head3 finish

 $cb->($connection)

Called when the connection is terminated

=head2 close

 $connection->close;
 $connection->close($code);
 $connection->close($code, $reason);

Close the connection.  You may optionally provide a code and a reason.
See L<section 5.5.1|https://tools.ietf.org/html/rfc6455#section-5.5.1> and L<section 7.4.1|https://tools.ietf.org/html/rfc6455#section-7.4.1> of RFC6455.

The code is a 16-bit unsigned integer value that indicates why you close the connection. By default the code is 1005.

The reason is a character string (not an octet string) that further describes why you close the connection. By default the reason is an empty string.

=head1 SERVER CONNECTIONS

Although written originally to work with L<AnyEvent::WebSocket::Client>,
this class was designed to be used for either client or server WebSocket
connections.  For details, contact the author and/or take a look at the
source for L<AnyEvent::WebSocket::Client> and the examples that come with
L<Protocol::WebSocket>.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::WebSocket::Client>

=item *

L<AnyEvent::WebSocket::Message>

=item *

L<AnyEvent::WebSocket::Server>

=item *

L<AnyEvent>

=item *

L<RFC 6455 The WebSocket Protocol|http://tools.ietf.org/html/rfc6455>

=back

=for stopwords Joaquín José

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Toshio Ito

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
