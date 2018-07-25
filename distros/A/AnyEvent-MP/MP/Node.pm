=head1 NAME

AnyEvent::MP::Node - represent a node

=head1 SYNOPSIS

   use AnyEvent::MP::Node;

=head1 DESCRIPTION

This is an internal utility module, horrible to look at, so don't.

=cut

package AnyEvent::MP::Node; # base class for nodes

use common::sense;

use AnyEvent ();
use AnyEvent::Socket ();

use AnyEvent::MP::Transport ();

sub new {
   my ($self, $id) = @_;

   $self = bless { id => $id }, $self;

   # register
   $AnyEvent::MP::Kernel::NODE{$id} = $self;

   $self->init;
   $self->transport_reset;

   $self
}

sub DESTROY {
   # unregister
   delete $AnyEvent::MP::Kernel::NODE{$_[0]{id}};
}

sub init {
   #
}

sub send {
   &{ shift->{send} }
}

# nodes reachable via the network
package AnyEvent::MP::Node::Remote; # a remote node

use base "AnyEvent::MP::Node";

# called at init time, mostly sets {send}
sub transport_reset {
   my ($self) = @_;

   delete $self->{transport};

   Scalar::Util::weaken $self;

   $self->{send} = sub {
      push @{$self->{queue}}, shift;
      $self->connect;
   };
}

# called each time we fail to establish a connection,
# or the existing connection failed
sub transport_error {
   my ($self, @reason) = @_;

   my $no_transport = !$self->{transport};

   delete $self->{connect_w};
   delete $self->{connect_to};

   delete $self->{queue};
   $self->transport_reset;

   if (my $mon = delete $self->{lmon}) {
      $_->(@reason) for map @$_, values %$mon;
   }

   AnyEvent::MP::Kernel::_inject_nodeevent ($self, 0, @reason)
      unless $no_transport;

   # we weaken the node reference, so it can go away if unused
   Scalar::Util::weaken $AnyEvent::MP::Kernel::NODE{$self->{id}}
      unless $self->{connect_to};

   AE::log 9 => "@reason";
}

# called after handshake was successful
sub transport_connect {
   my ($self, $transport) = @_;

   delete $self->{trial};

   $self->transport_error (transport_error => $self->{id}, "switched connections")
      if $self->{transport};

   delete $self->{connect_w};
   delete $self->{connect_to};

   $self->{transport} = $transport;

   my $transport_send = $transport->{send};

   AnyEvent::MP::Kernel::_inject_nodeevent ($self, 1);

   $self->{send} = $transport_send;

   $transport_send->($_)
      for @{ delete $self->{queue} || [] };
}

sub connect {
   my ($self) = @_;

   return if $self->{transport};
   return if $self->{connect_w};

   # we unweaken the node reference, in case it was weakened before
   $AnyEvent::MP::Kernel::NODE{$self->{id}}
      = $AnyEvent::MP::Kernel::NODE{$self->{id}};

   Scalar::Util::weaken $self;

   $self->{connect_to} ||= AE::timer $AnyEvent::MP::Kernel::CONFIG->{connect_interval}, 0, sub {
      $self->transport_error (transport_error => $self->{id}, "connect timeout");
   };

   # maybe @$addresses?
   my $addresses = $AnyEvent::MP::Kernel::GLOBAL_DB{"'l"}{$self->{id}};

   if ($addresses) {
      $self->connect_to ($addresses);
   } else {
      # on global nodes, all bets are off now - we either know the node, or we don't
      if ($AnyEvent::MP::Kernel::GLOBAL) {
         $self->transport_error (transport_error => $self->{id}, "no known address");
      } else {
         AnyEvent::MP::Kernel::g_find ($self->{id});
      }
   }
}

sub connect_to {
   my ($self, $addresses) = @_;

   return if $self->{transport};
   return if $self->{connect_w};

   unless (@$addresses) {
      $self->transport_error (transport_error => $self->{id}, "no known address");
      return;
   }
   
   AE::log 9 => "connecting to $self->{id} with [@$addresses]";

   my $monitor  = $AnyEvent::MP::Kernel::CONFIG->{monitor_timeout};
   my $interval = $AnyEvent::MP::Kernel::CONFIG->{connect_interval};

   $interval = ($monitor - $interval) / @$addresses
      if ($monitor - $interval) / @$addresses < $interval;

   $interval = 0.4 if $interval < 0.4;

   my @endpoints = reverse @$addresses;

   $self->{connect_w} = AE::timer 0, $interval * (0.9 + 0.1 * rand), sub {
      my $endpoint = pop @endpoints
         or return;

      AE::log 9 => "connecting to $self->{id} at $endpoint";

      $self->{trial}{$endpoint} ||= do {
         my ($host, $port) = AnyEvent::Socket::parse_hostport $endpoint
            or return AE::log critical => "$self->{id}: '$endpoint' is not a resolved node reference.";

         AnyEvent::MP::Transport::mp_connect
            $host, $port,
            sub { delete $self->{trial}{$endpoint} },
      };
   };
}

sub kill {
   my ($self, $port, @reason) = @_;

   $self->{send} (["", kil1 => $port, @reason]);
}

sub monitor {
   my ($self, $portid, $cb) = @_;

   my $list = $self->{lmon}{$portid} ||= [];

   $self->send (["", mon1 => $portid])
      unless @$list || !length $portid;

   push @$list, $cb;
}

sub unmonitor {
   my ($self, $portid, $cb) = @_;

   my $list = $self->{lmon}{$portid}
      or return;

   @$list = grep $_ != $cb, @$list;

   unless (@$list) {
      $self->send (["", mon0 => $portid]);
      delete $self->{monitor}{$portid};
   }
}

package AnyEvent::MP::Node::Self; # the local node

use base "AnyEvent::MP::Node";

sub connect {
   # we are trivially connected
}

# delay every so often to avoid recursion, also used to delay after spawn
our $DELAY = -50;
our @DELAY;
our $DELAY_W;

our $send_delayed = sub {
   $AnyEvent::MP::Kernel::SRCNODE = $AnyEvent::MP::Kernel::NODE;
   (shift @DELAY)->()
      while @DELAY;
   undef $DELAY_W;
   $DELAY = -50;
};

sub transport_reset {
   my ($self) = @_;

   Scalar::Util::weaken $self;

   $self->{send} = sub {
      if (++$DELAY > 0) {
         my $msg = $_[0];
         push @DELAY, sub { AnyEvent::MP::Kernel::_inject (@$msg) };
         $DELAY_W ||= AE::timer 0, 0, $send_delayed;
         return;
      }

      local $AnyEvent::MP::Kernel::SRCNODE = $AnyEvent::MP::Kernel::NODE;
      AnyEvent::MP::Kernel::_inject (@{ $_[0] });
   };
}

sub transport_connect {
   my ($self, $tp) = @_;

   AE::log 9 => "I refuse to talk to myself ($tp->{peerhost}:$tp->{peerport})";
}

sub kill {
   my (undef, @args) = @_;

   # we _always_ delay kil's, to avoid calling mon callbacks
   # from anything but the event loop context.
   $DELAY = 1;
   push @DELAY, sub { AnyEvent::MP::Kernel::_kill (@args) };
   $DELAY_W ||= AE::timer 0, 0, $send_delayed;
}

sub monitor {
   # maybe always delay, too?
   if ($DELAY_W) {
      my @args = @_;
      push @DELAY, sub { AnyEvent::MP::Kernel::_monitor (@args) };
      return;
   }
   &AnyEvent::MP::Kernel::_monitor;
}

sub unmonitor {
   # no need to always delay
   if ($DELAY_W) {
      my @args = @_;
      push @DELAY, sub { AnyEvent::MP::Kernel::_unmonitor (@args) };
      return;
   }

   &AnyEvent::MP::Kernel::_unmonitor;
}

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

