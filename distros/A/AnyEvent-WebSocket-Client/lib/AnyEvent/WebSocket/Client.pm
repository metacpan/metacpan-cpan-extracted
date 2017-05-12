package AnyEvent::WebSocket::Client;

use strict;
use warnings;
use Moo;
use AE;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket ();
use Protocol::WebSocket::Request;
use Protocol::WebSocket::Handshake::Client;
use AnyEvent::WebSocket::Connection;
use PerlX::Maybe qw( maybe provided );

# ABSTRACT: WebSocket client for AnyEvent
our $VERSION = '0.38'; # VERSION


has timeout => (
  is      => 'ro',
  default => sub { 30 },
);


has ssl_no_verify => (
  is => 'ro',
);


has ssl_ca_file => (
  is => 'ro',
);


has protocol_version => (
  is => 'ro',
);


has subprotocol => (
  is     => 'ro',
  coerce => sub { ref $_[0] ? $_[0] : [$_[0]] },
);


has http_headers => (
  is => 'ro',
  coerce => sub {
    ref $_[0] eq 'ARRAY' ? $_[0] : do {
      my $h = shift;
      [
        map {
          my($k,$v) = ($_, $h->{$_});
          $v = [$v] unless ref $v;
          map { $k => $_ } @$v;
          # sorted to make testing easier.
          # may be removed in the future
          # so do not depend on it.
        } sort keys %$h
      ],
    };
  },
);


has max_payload_size => (
  is => 'ro',
);


sub connect
{
  my($self, $uri) = @_;
  unless(ref $uri)
  {
    require URI;
    $uri = URI->new($uri);
  }
  
  my $done = AE::cv;

  # TODO: should we also accept http and https URLs?
  # probably.
  if($uri->scheme ne 'ws' && $uri->scheme ne 'wss')
  {
    $done->croak("URI is not a websocket");
    return $done;
  }
    
  AnyEvent::Socket::tcp_connect $uri->host, $uri->port, sub {
    my $fh = shift;
    unless($fh)
    {
      $done->croak("unable to connect");
      return;
    }
    my $req = Protocol::WebSocket::Request->new( maybe headers => $self->http_headers );
    my $handshake = Protocol::WebSocket::Handshake::Client->new(
            url     => $uri->as_string,
      maybe version => $self->protocol_version,
            req     => $req,
    );
    
    my %subprotocol;
    if($self->subprotocol)
    {
      %subprotocol = map { $_ => 1 } @{ $self->subprotocol };
      $handshake->req->subprotocol(join(',', @{ $self->subprotocol }));
    }
    
    my $hdl = AnyEvent::Handle->new(
                                                      fh       => $fh,
      provided $uri->secure,                          tls      => 'connect',
      provided $uri->secure && !$self->ssl_no_verify, peername => $uri->host,
      provided $uri->secure && !$self->ssl_no_verify, tls_ctx  => {
                                                              verify => 1,
                                                              verify_peername => "https",
                                                        maybe ca_file => $self->ssl_ca_file,
                                                      },
                                                      on_error => sub {
                                                        my ($hdl, $fatal, $msg) = @_;
                                                        if($fatal)
                                                        { $done->croak("connect error: " . $msg) }
                                                        else
                                                        { warn $msg }
                                                      },
    );

    $hdl->push_write($handshake->to_string);
    $hdl->on_read(sub {
      $handshake->parse($_[0]{rbuf});
      if($handshake->error)
      {
        $done->croak("handshake error: " . $handshake->error);
        undef $hdl;
        undef $handshake;
        undef $done;
      }
      elsif($handshake->is_done)
      {
        my $sb;
        if($self->subprotocol)
        {
          $sb = $handshake->res->subprotocol;
          if(defined $sb)
          {
            unless($subprotocol{$sb})
            {
              $done->croak("subprotocol mismatch, requested: @{[ join ', ', @{ $self->subprotocol } ]}, got: $sb");
            }
          }
          else
          {
            $done->croak("no subprotocol in response");
          }
        }
        undef $handshake;
        $done->send(
          AnyEvent::WebSocket::Connection->new(
                  handle           => $hdl,
                  masked           => 1,
            maybe subprotocol      => $sb,
            maybe max_payload_size => $self->max_payload_size,
          )
        );
        undef $hdl;
        undef $done;
      }
    });
  }, sub { $self->timeout };
  $done;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::WebSocket::Client - WebSocket client for AnyEvent

=head1 VERSION

version 0.38

=head1 SYNOPSIS

 use AnyEvent::WebSocket::Client 0.12;
 
 my $client = AnyEvent::WebSocket::Client->new;
 
 $client->connect("ws://localhost:1234/service")->cb(sub {
 
   # make $connection an our variable rather than
   # my so that it will stick around.  Once the
   # connection falls out of scope any callbacks
   # tied to it will be destroyed.
   our $connection = eval { shift->recv };
   if($@) {
     # handle error...
     warn $@;
     return;
   }
   
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

   # close the connection (either inside or
   # outside another callback)
   $connection->close;
 
 });

 ## uncomment to enter the event loop before exiting.
 ## Note that calling recv on a condition variable before
 ## it has been triggered does not work on all event loops
 #AnyEvent->condvar->recv;

=head1 DESCRIPTION

This class provides an interface to interact with a web server that provides
services via the WebSocket protocol in an L<AnyEvent> context.  It uses
L<Protocol::WebSocket> rather than reinventing the wheel.  You could use 
L<AnyEvent> and L<Protocol::WebSocket> directly if you wanted finer grain
control, but if that is not necessary then this class may save you some time.

The recommended API was added to the L<AnyEvent::WebSocket::Connection>
class with version 0.12, so it is recommended that you include that version
when using this module.  The older version of the API has since been
deprecated and removed.

=head1 ATTRIBUTES

=head2 timeout

Timeout for the initial connection to the web server.  The default
is 30.

=head2 ssl_no_verify

If set to true, then secure WebSockets (those that use SSL/TLS) will
not be verified.  The default is false.

=head2 ssl_ca_file

Provide your own CA certificates file instead of using the system default for
SSL/TLS verification.

=head2 protocol_version

The protocol version.  See L<Protocol::WebSocket> for the list of supported
WebSocket protocol versions.

=head2 subprotocol

List of subprotocols to request from the server.  This class will throw an
exception if none of the protocols are supported by the server.

=head2 http_headers

Extra headers to include in the initial request.  May be either specified
as a hash reference, or an array reference.  For example:

 AnyEvent::WebSocket::Client->new(
   http_headers => {
     'X-Foo' => 'bar',
     'X-Baz' => [ 'abc', 'def' ],
   },
 );
 
 AnyEvent::WebSocket::Client->new(
   http_headers => [
     'X-Foo' => 'bar',
     'X-Baz' => 'abc',
     'X-Baz' => 'def',
   ],
 );

Will generate:

 X-Foo: bar
 X-Baz: abc
 X-Baz: def

Although, the order cannot be guaranteed when using the hash style.

=head2 max_payload_size

The maximum payload size for received frames.  Currently defaults to whatever
L<Protocol::WebSocket> defaults to.

=head1 METHODS

=head2 connect

 my $cv = $client->connect($uri)

Open a connection to the web server and open a WebSocket to the resource
defined by the given URL.  The URL may be either an instance of L<URI::ws>,
L<URI::wss>, or a string that represents a legal WebSocket URL.

This method will return an L<AnyEvent> condition variable which you can 
attach a callback to.  The value sent through the condition variable will
be either an instance of L<AnyEvent::WebSocket::Connection> or a croak
message indicating a failure.  The synopsis above shows how to catch
such errors using C<eval>.

=head1 FAQ

=head2 My program exits before doing anything, what is up with that?

See this FAQ from L<AnyEvent>: 
L<AnyEvent::FAQ#My-program-exits-before-doing-anything-whats-going-on>.

It is probably also a good idea to review the L<AnyEvent> documentation
if you are new to L<AnyEvent> or event-based programming.

=head2 My callbacks aren't being called!

Make sure that the connection object is still in scope.  This often happens
if you use a C<my $connection> variable and don't save it somewhere.  For
example:

 $client->connect("ws://foo/service")->cb(sub {
 
   my $connection = eval { shift->recv };
   
   if($@)
   {
     warn $@;
     return;
   }
   
   ...
 });

Unless C<$connection> is saved somewhere it will get deallocated along with
any associated message callbacks will also get deallocated once the connect
callback is executed.  One way to make sure that the connection doesn't
get deallocated is to make it a C<our> variable (as in the synopsis above)
instead.

=head1 CAVEATS

This is pretty simple minded and there are probably WebSocket features
that you might like to use that aren't supported by this distribution.
Patches are encouraged to improve it.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::WebSocket::Connection>

=item *

L<AnyEvent::WebSocket::Message>

=item *

L<AnyEvent::WebSocket::Server>

=item *

L<AnyEvent>

=item *

L<URI::ws>

=item *

L<URI::wss>

=item *

L<Protocol::WebSocket>

=item *

L<Net::WebSocket::Server>

=item *

L<Net::Async::WebSocket>

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
