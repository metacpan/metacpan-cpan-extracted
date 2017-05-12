=head1 NAME

Coro::Socket - non-blocking socket-I/O

=head1 SYNOPSIS

 use Coro::Socket;

 # listen on an ipv4 socket
 my $socket = new Coro::Socket PeerHost => "localhost",
                               PeerPort => 'finger';

 # listen on any other type of socket
 my $socket = Coro::Socket->new_from_fh
                 (IO::Socket::UNIX->new
                     Local  => "/tmp/socket",
                     Type   => SOCK_STREAM,
                 );

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements socket-handles in a coroutine-compatible way,
that is, other coroutines can run while reads or writes block on the
handle. See L<Coro::Handle>, especially the note about prefering method
calls.

=head1 IPV6 WARNING

This module was written to imitate the L<IO::Socket::INET> API, and derive
from it. Since IO::Socket::INET does not support IPv6, this module does
neither.

Therefore it is not recommended to use Coro::Socket in new code. Instead,
use L<AnyEvent::Socket> and L<Coro::Handle>, e.g.:

   use Coro;
   use Coro::Handle;
   use AnyEvent::Socket;

   # use tcp_connect from AnyEvent::Socket
   # and call Coro::Handle::unblock on it.

   tcp_connect "www.google.com", 80, Coro::rouse_cb;
   my $fh = unblock +(Coro::rouse_wait)[0];

   # now we have a perfectly thread-safe socket handle in $fh
   print $fh "GET / HTTP/1.0\015\012\015\012";
   local $/;
   print <$fh>;

Using C<AnyEvent::Socket::tcp_connect> gives you transparent IPv6,
multi-homing, SRV-record etc. support.

For listening sockets, use C<AnyEvent::Socket::tcp_server>.

=over 4

=cut

package Coro::Socket;

use common::sense;

use Errno ();
use Carp qw(croak);
use Socket;
use IO::Socket::INET ();

use Coro::Util ();

use base qw(Coro::Handle IO::Socket::INET);

our $VERSION = 6.511;

our (%_proto, %_port);

sub _proto($) {
   $_proto{$_[0]} ||= do {
      ((getprotobyname $_[0])[2] || (getprotobynumber $_[0])[2])
         or croak "unsupported protocol: $_[0]";
   };
}

sub _port($$) {
   $_port{$_[0],$_[1]} ||= do {
      return $_[0] if $_[0] =~ /^\d+$/;

      $_[0] =~ /([^(]+)\s*(?:\((\d+)\))?/x
         or croak "unparsable port number: $_[0]";
      ((getservbyname $1, $_[1])[2]
        || (getservbyport $1, $_[1])[2]
        || $2)
         or croak "unknown port: $_[0]";
   };
}

sub _sa($$$) {
   my ($host, $port, $proto) = @_;

   $port or $host =~ s/:([^:]+)$// and $port = $1;

   my $_proto = _proto($proto);
   my $_port = _port($port, $proto);

   my $_host = Coro::Util::inet_aton $host
      or croak "$host: unable to resolve";

   pack_sockaddr_in $_port, $_host
}

=item $fh = new Coro::Socket param => value, ...

Create a new non-blocking tcp handle and connect to the given host
and port. The parameter names and values are mostly the same as for
IO::Socket::INET (as ugly as I think they are).

The parameters officially supported currently are: C<ReuseAddr>,
C<LocalPort>, C<LocalHost>, C<PeerPort>, C<PeerHost>, C<Listen>, C<Timeout>,
C<SO_RCVBUF>, C<SO_SNDBUF>.

   $fh = new Coro::Socket PeerHost => "localhost", PeerPort => 'finger';

=cut

sub _prepare_socket {
   my ($self, $arg) = @_;

   $self
}
   
sub new {
   my ($class, %arg) = @_;

   $arg{Proto}     ||= 'tcp';
   $arg{LocalHost} ||= delete $arg{LocalAddr};
   $arg{PeerHost}  ||= delete $arg{PeerAddr};
   defined ($arg{Type}) or $arg{Type} = $arg{Proto} eq "tcp" ? SOCK_STREAM : SOCK_DGRAM;

   socket my $fh, PF_INET, $arg{Type}, _proto ($arg{Proto})
      or return;

   my $self = bless Coro::Handle->new_from_fh (
      $fh,
      timeout       => $arg{Timeout},
      forward_class => $arg{forward_class},
      partial       => $arg{partial},
   ), $class
      or return;

   $self->configure (\%arg)
}

sub configure {
   my ($self, $arg) = @_;

   if ($arg->{ReuseAddr}) {
      $self->setsockopt (SOL_SOCKET, SO_REUSEADDR, 1)
         or croak "setsockopt(SO_REUSEADDR): $!";
   }

   if ($arg->{ReusePort}) {
      $self->setsockopt (SOL_SOCKET, SO_REUSEPORT, 1)
         or croak "setsockopt(SO_REUSEPORT): $!";
   }

   if ($arg->{Broadcast}) {
      $self->setsockopt (SOL_SOCKET, SO_BROADCAST, 1)
         or croak "setsockopt(SO_BROADCAST): $!";
   }

   if ($arg->{SO_RCVBUF}) {
      $self->setsockopt (SOL_SOCKET, SO_RCVBUF, $arg->{SO_RCVBUF})
         or croak "setsockopt(SO_RCVBUF): $!";
   }

   if ($arg->{SO_SNDBUF}) {
      $self->setsockopt (SOL_SOCKET, SO_SNDBUF, $arg->{SO_SNDBUF})
         or croak "setsockopt(SO_SNDBUF): $!";
   }

   if ($arg->{LocalPort} || $arg->{LocalHost}) {
      my @sa = _sa($arg->{LocalHost} || "0.0.0.0", $arg->{LocalPort} || 0, $arg->{Proto});
      $self->bind ($sa[0])
         or croak "bind($arg->{LocalHost}:$arg->{LocalPort}): $!";
   }

   if ($arg->{PeerHost}) {
      my @sa = _sa ($arg->{PeerHost}, $arg->{PeerPort}, $arg->{Proto});

      for (@sa) {
         $! = 0;

         if ($self->connect ($_)) {
            next unless writable $self;
            $! = unpack "i", $self->getsockopt (SOL_SOCKET, SO_ERROR);
         }

         $! or last;

         $!{ECONNREFUSED} or $!{ENETUNREACH} or $!{ETIMEDOUT} or $!{EHOSTUNREACH}
            or return;
      }
   } elsif (exists $arg->{Listen}) {
      $self->listen ($arg->{Listen})
         or return;
   }

   $self
}

1;

=back

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

