=head1 NAME

AnyEvent::MP::DataConn - create socket connections between nodes

=head1 SYNOPSIS

   use AnyEvent::MP::DataConn;

=head1 DESCRIPTION

This module can be used to create socket connections between the local and
a remote node in the aemp network. The socket can be used freely for any
purpose, and in most cases, this mechanism is a good way to transport big
chunks of binary data.

The connections created by this module use the same security mechanisms
as normal AEMP connections (secure authentication, optional use of TLS),
and in fact, use the same listening port as AEMP connections, so when two
nodes can reach each other via the normal aemp protocol, they can create
data connections as well, no extra ports or firewall rules are required.

The protocol used is, however, not the AEMP transport protocol, so this
will only work between nodes implementing the "aemp-dataconn" protocol
extension.

=head1 FUNCTIONS

=over 4

=cut

package AnyEvent::MP::DataConn;

use common::sense;
use Carp ();
use POSIX ();

use AnyEvent ();
use AnyEvent::Util ();

use AnyEvent::MP;
use AnyEvent::MP::Kernel ();
use AnyEvent::MP::Global ();

our $ID = "a";
our %STATE;

# another node tells us to await a connection
sub _expect {
   my ($id, $port, $timeout, $initfunc, @initdata) = @_;

   $STATE{$id} = {
      id   => $id,
      to   => (AE::timer $timeout, 0, sub {
         $STATE{$id}{done}(undef);
      }),
      done => sub {
         my ($hdl, $error) = @_;

         %{delete $STATE{$id}} = ();

         if (defined $hdl) {
            (AnyEvent::MP::Kernel::load_func $initfunc)->(@initdata, $hdl);
         } else {
            kil $port, AnyEvent::MP::DataConn:: => $error;
         }
      },
   };
}

# AEMP::Transport call for dataconn-connections
sub _inject {
   my ($conn, $error) = @_;

   my $hdl = defined $error ? undef : delete $conn->{hdl};
   my $id = $conn->{local_greeting}{dataconn_id} || $conn->{remote_greeting}{dataconn_id}
      or return;

   $conn->destroy;

   ($STATE{$id} or return)->{done}($hdl, $error);
}

# actively connect to some other node
sub _connect {
   my ($id, $node) = @_;

   my $state = $STATE{$id}
      or return;

   my $addr = $AnyEvent::MP::Global::addr{$node};

   @$addr
      or return $state->{done}(undef, "$node: no listeners found");

   # I love hardcoded constants  !
   $state->{next} = AE::timer 0, 2, sub {
      my $endpoint = shift @$addr
         or return delete $state->{next};

      my ($host, $port) = AnyEvent::Socket::parse_hostport $endpoint
         or return;

      my $transport; $transport = AnyEvent::MP::Transport::mp_connect
         $host, $port,
         protocol => "aemp-dataconn",
         local_greeting => { dataconn_id => $id },
         sub { $transport->destroy }, #TODO: destroys handshaked conenctions too early
      ;
   };
}

=item AnyEvent::MP::DataConn::connect_to $node, $timeout, $initfunc, @initdata, $cb->($handle)

Creates a socket connection between the local node and the node C<$node>
(which can also be specified as a port). One of the nodes must have
listening ports ("binds").

When the connection could be successfully created, the C<$initfunc>
will be called with the given C<@initdata> on the remote node (similar
to C<snd_to_func> or C<spawn>), and the C<AnyEvent::Handle> object
representing the remote connection end as additional argument.

Also, the callback given as last argument will be called with the
AnyEvent::Handle object for the local side.

The AnyEvent::Handle objects will be in a "quiescent" state - you could rip
out the file handle and forget about it, but it is recommended to use it,
as the security settings might have called for a TLS connection. If you
opt to use it, you at least have to set an C<on_error> callback.

In case of any error (timeout etc.), nothing will be called on
the remote side, and the local port will be C<kil>'ed with an C<<
AnyEvent::MP::DataConn => "error message" >> kill reason.

The timeout should be large enough to cover at least four network
round-trips and one message round-trip.

Example: on node1, establish a connection to node2 and send a line of text,
one node2, provide a receiver function.

   # node1, code executes in some port context
   AnyEvent::MP::DataConn::connect_to "node2", 5, "pkg::receiver", 1, sub {
      my ($hdl) = @_;
      warn "connection established, sending line.\n"
      $hdl->push_write ("blabla\n")
   };

   # node2
   sub pkg::receiver {
      my ($one, $hdl) = @_;
      warn "connection established, wait for a line...\n"

      $hdl->push_read (line => sub {
         warn "received a line: $_[1]\n";
         undef $hdl;
      });
   }

=cut

sub connect_to($$$$@) {
   my $cb = pop;
   my ($node, $timeout, $initfunc, @initdata) = @_;

   my $port = $SELF
      or Carp::croak "AnyEvent::MP::DataConn::connect_to must be called in port context";

   $node = node_of $node;

   my $id = (++$ID) . "\@$NODE";

   # damn, why do my simple state hashes resemble objects so quickly
   my $state = $STATE{$id} = {
      id   => (++$ID) . "\@$NODE",
      to   => (AE::timer $timeout, 0, sub {
         $STATE{$id}{done}(undef, "$node: unable to establish connection within $timeout seconds");
      }),
      done => sub {
         my ($hdl, $error) = @_;

         delete $AnyEvent::MP::Global::ON_SETUP{$id};
         %{delete $STATE{$id}} = ();

         if (defined $hdl) {
            $cb->($hdl);
         } else {
            kil $port, AnyEvent::MP::DataConn:: => $error;
         }
      },
   };

   if (AnyEvent::MP::Kernel::port_is_local $node) {
      # teh sucks

      require AnyEvent::Util;
      my ($fh1, $fh2) = AnyEvent::Util::portable_socketpair ()
         or return kil $port, AnyEvent::MP::DataConn:: => "cannot create local socketpair: $!";

      use AnyEvent::Handle;
      my $hdl1 = new AnyEvent::Handle fh => $fh1;
      my $hdl2 = new AnyEvent::Handle fh => $fh2;

      (AnyEvent::MP::Kernel::load_func $initfunc)->(@initdata, $hdl2);
      $cb->($hdl1);

   } else {
      AnyEvent::MP::Kernel::snd_to_func $node,
         AnyEvent::MP::DataConn::_expect:: => $id, $port, $timeout, $initfunc, @initdata;

      $state->{wait} = sub {
         if (my $addr = $AnyEvent::MP::Global::addr{$node}) {
            delete $AnyEvent::MP::Global::ON_SETUP{$id};

            # continue connect
            if (@$addr) {
               # node has listeners, so connect
               _connect $id, $node;
            } else {
               # no listeners, ask it to connect to us
               AnyEvent::MP::Kernel::snd_to_func $node, AnyEvent::MP::DataConn::_connect:: => $id, $NODE;
            }
         } else {
            # wait for the next global setup handshake
            # due to the round-trip at the beginning, this should never be necessary
            $AnyEvent::MP::Global::ON_SETUP{$id} = $state->{wait};
         };
      };

      # we actually have to make sure that the connection arrives after the expect message, and
      # the easiest way to do this is to use an rpc call.
      AnyEvent::MP::Kernel::snd_on $node, port { $state->{wait}() };
   }
}

=back

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

