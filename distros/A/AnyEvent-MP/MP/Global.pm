=head1 NAME

AnyEvent::MP::Global - some network-global services

=head1 SYNOPSIS

   use AnyEvent::MP::Global;

=head1 DESCRIPTION

This module maintains a fully-meshed network, if possible, and tries to
ensure that we are connected to at least one other node.

It also manages named port groups - ports can register themselves in any
number of groups that will be available network-wide, which is great for
discovering services.

Running it on one node will automatically run it on all nodes, although,
at the moment, the global service is started by default anyways.

=head1 GLOBALS AND FUNCTIONS

=over 4

=cut

package AnyEvent::MP::Global;

use common::sense;
use Carp ();

use AnyEvent ();
use AnyEvent::Util ();

use AnyEvent::MP;
use AnyEvent::MP::Kernel;
use AnyEvent::MP::Transport ();

use base "Exporter";

our @EXPORT = qw(
   grp_reg
   grp_get
   grp_mon
);

our $GLOBAL_VERSION = 0;

our %ON_SETUP; # take note: not public

our %addr; # port ID => [address...] mapping

our %port; # our rendezvous port on the other side
our %lreg; # local registry, name => [pid...]
our %lmon; # local registry monitoring name,pid => mon
our %greg; # global regstry, name => pid => undef
our %gmon; # group monitoring, group => [$cb...]

our $nodecnt;

$AnyEvent::MP::Kernel::WARN->(7, "starting global service.");

#############################################################################
# seednodes

our $MASTER; # our current master (which we regularly query for net updates)

our %SEEDME; # $node => $port
our @SEEDS;
our %SEEDS; # just to check whether a seed is a seed
our %SEED_CONNECT;
our $SEED_WATCHER;

push @AnyEvent::MP::Transport::HOOK_CONNECT, sub {
   my $peer = $_[0]{local_greeting}{peeraddr};
   return unless exists $SEEDS{$peer};
   $SEED_CONNECT{$peer} = 2;
};

push @AnyEvent::MP::Transport::HOOK_GREETING, sub {
   # we rely on untrusted data here (the remote node name)
   # this is hopefully ok, as we override it on successful
   # connects, and this can at most be used for DOSing,
   # which is easy when you can do MITM.
   my $peer = $_[0]{local_greeting}{peeraddr};
   return unless exists $SEEDS{$peer};
   $SEEDS{$peer} ||= $_[0]{remote_node};
};

push @AnyEvent::MP::Transport::HOOK_CONNECTED, sub {
   my $peer = $_[0]{local_greeting}{peeraddr};
   return unless exists $SEEDS{$peer};
   $SEEDS{$peer} = $_[0]{remote_node};
};

push @AnyEvent::MP::Transport::HOOK_DESTROY, sub {
   delete $SEED_CONNECT{$_[0]{local_greeting}{peeraddr}};

   # check if we contacted ourselves, so nuke this seed
   if (exists $_[0]{seed} && $_[0]{remote_node} eq $AnyEvent::MP::Kernel::NODE) {
#      $AnyEvent::MP::Kernel::WARN->(0,"avoiding seed $_[0]{seed}\n");#d#
      delete $SEEDS{$_[0]{seed}};
   }
};

sub seed_connect {
   my ($seed) = @_;

   my ($host, $port) = AnyEvent::Socket::parse_hostport $seed
      or Carp::croak "$seed: unparsable seed address";

   return if $SEED_CONNECT{$seed};
   return if defined $SEEDS{$seed} && node_is_up $SEEDS{$seed};

   $AnyEvent::MP::Kernel::WARN->(9, "trying connect to seed node $seed.");

   # ughhh
   $SEED_CONNECT{$seed} ||= AnyEvent::MP::Transport::mp_connect $host, $port,
      seed => $seed,
      sub {
         $SEED_CONNECT{$seed} = 1;
      },
   ;
}

sub more_seeding {
   my $int = List::Util::max 1,
                $AnyEvent::MP::Kernel::CONFIG->{connect_interval}
                * ($nodecnt ? keys %AnyEvent::MP::Kernel::NODE : 1)
                - rand;

   $SEED_WATCHER = AE::timer $int, 0, \&more_seeding;

   @SEEDS = keys %SEEDS unless @SEEDS;
   return unless @SEEDS;

   seed_connect splice @SEEDS, rand @SEEDS, 1;
}

sub set_seeds(@) {
   @SEEDS{@_} = ();

   $SEED_WATCHER ||= AE::timer 5, $AnyEvent::MP::Kernel::MONITOR_TIMEOUT, \&more_seeding;

   after 0.100 * rand, \&more_seeding
      for 1 .. keys %SEEDS;
}

sub up_seeds() {
   grep node_is_up $_, values %SEEDS
}

sub node_is_seed($) {
   grep $_ eq $_[0], grep defined, values %SEEDS
}

# returns all (up) seed nodes, or all nodes if no seednodes are up/known
sub route_nodes {
   my @seeds = up_seeds;
   @seeds = up_nodes unless @seeds;
   @seeds
}

#############################################################################

sub _change {
   my ($group, $add, $del) = @_;

   my $kv = $greg{$group} ||= {};

   delete @$kv{@$del};
   @$kv{@$add} = ();

   my $ports = [keys %$kv];
   $_->($ports, $add, $del) for @{ $gmon{$group} };
}

sub unreg_groups($) {
   my ($node) = @_;

   my $qr = qr/^\Q$node\E(?:#|$)/;
   my @del;

   while (my ($group, $ports) = each %greg) {
      @del = grep /$qr/, keys %$ports;
      _change $group, [], \@del
         if @del;
   }
}

sub set_groups($$) {
   my ($node, $lreg) = @_;

   while (my ($k, $v) = each %$lreg) {
      _change $k, $v, [];
   }
}

=item $guard = grp_reg $group, $port

Register the given (local!) port in the named global group C<$group>.

The port will be unregistered automatically when the port is destroyed.

When not called in void context, then a guard object will be returned that
will also cause the name to be unregistered when destroyed.

=cut

# unregister local port
sub unregister {
   my ($port, $group) = @_;

   delete $lmon{"$group\x00$port"};
   @{ $lreg{$group} } = grep $_ ne $port, @{ $lreg{$group} };

   _change $group, [], [$port];

   snd $_, reg0 => $group, $port
      for values %port;
}

# register local port
sub grp_reg($$) {
   my ($group, $port) = @_;

   port_is_local $port
      or Carp::croak "AnyEvent::MP::Global::grp_reg can only be called for local ports, caught";

   grep $_ eq $port, @{ $lreg{$group} }
      and Carp::croak "'$group': group already registered, cannot register a second time";

   $lmon{"$group\x00$port"} = mon $port, sub { unregister $port, $group };
   push @{ $lreg{$group} }, $port;

   snd $_, reg1 => $group, $port
      for values %port;

   _change $group, [$port], [];

   defined wantarray && AnyEvent::Util::guard { unregister $port, $group }
}

=item $ports = grp_get $group

Returns all the ports currently registered to the given group (as
read-only(!) array reference). When the group has no registered members,
return C<undef>.

=cut

sub grp_get($) {
   my @ports = keys %{ $greg{$_[0]} };
   @ports ? \@ports : undef
}

=item $guard = grp_mon $group, $callback->($ports, $add, $del)

Installs a monitor on the given group. Each time there is a change it
will be called with the current group members as an arrayref as the
first argument. The second argument only contains ports added, the third
argument only ports removed.

Unlike C<grp_get>, all three arguments will always be array-refs, even if
the array is empty. None of the arrays must be modified in any way.

The first invocation will be with the first two arguments set to the
current members, as if all of them were just added, but only when the
group is actually non-empty.

Optionally returns a guard object that uninstalls the watcher when it is
destroyed.

=cut

sub grp_mon($$) {
   my ($grp, $cb) = @_;

   AnyEvent::MP::Kernel::delay sub {
      return unless $cb;

      push @{ $gmon{$grp} }, $cb;
      $cb->(((grp_get $grp) || return) x 2, []);
   };

   defined wantarray && AnyEvent::Util::guard {
      my @mon = grep $_ != $cb, @{ delete $gmon{$grp} };
      $gmon{$grp} = \@mon if @mon;
      undef $cb;
   }
}

sub start_node {
   my ($node) = @_;

   return if exists $port{$node};
   return if $node eq $NODE; # do not connect to ourselves

   # establish connection
   my $port = $port{$node} = spawn $node, "AnyEvent::MP::Global::connect", $GLOBAL_VERSION, $NODE;

   mon $port, sub {
      unreg_groups $node;
      delete $port{$node};
   };

   snd $port, addr => $AnyEvent::MP::Kernel::LISTENER;
   snd $port, nodes => \%addr if %addr;
   snd $port, set => \%lreg if %lreg;
   snd $port, "setup"; # tell the other side that we are in business now
}

# other nodes connect via this
sub connect {
   my ($version, $node) = @_;

   (int $version) == (int $GLOBAL_VERSION)
      or die "node version mismatch (requested $version; we have $GLOBAL_VERSION)";

   # monitor them, silently die
   mon $node, psub {
      delete $SEEDME{$node};
      kil $SELF;
   };

   rcv $SELF,
      setup => sub {
         $_->($node) for values %ON_SETUP;
      },
      addr => sub {
         my $addresses = shift;
         $AnyEvent::MP::Kernel::WARN->(9, "$node told us its addresses (@$addresses).");
         $addr{$node} = $addresses;

         # delay broadcast by a random amount, to avoid nodes connecting to each other
         # at the same time.
         after 2 + rand, sub {
            for my $slave (keys %SEEDME) {
               snd $port{$slave} || next, nodes => { $node => $addresses };
            }
         };
      },
      nodes => sub {
         my ($kv) = @_;

         use JSON::XS;#d#
         my $kv_txt = JSON::XS->new->encode ($kv);#d#
         $AnyEvent::MP::Kernel::WARN->(9, "$node told us it knows about $kv_txt.");#d#

         while (my ($id, $addresses) = each %$kv) {
            my $node = AnyEvent::MP::Kernel::add_node $id;
            $node->connect (@$addresses);
            start_node $id;
         }
      },
      set => sub {
         set_groups $node, shift;
      },
      find => sub {
         my ($othernode) = @_;

         $AnyEvent::MP::Kernel::WARN->(9, "$node asked us to find $othernode.");
         snd $port{$node}, nodes => { $othernode => $addr{$othernode} }
            if $addr{$othernode};
      },
      reg0 => sub {
         _change $_[0], [], [$_[1]];
      },
      reg1 => sub {
         _change $_[0], [$_[1]], [];
      },

      # some node asks us to provide network updates
      seedme0 => sub {
         $AnyEvent::MP::Kernel::WARN->(9, "$node asked us to NOT seed it.");#d#
         delete $SEEDME{$node};
      },
      seedme1 => sub {
         $AnyEvent::MP::Kernel::WARN->(9, "$node asked us to seed it.");#d#
         $SEEDME{$node} = ();

         # for good measure
         snd $port{$node}, nodes => \%addr if %addr;
      },
   ;
}

sub set_master($) {
   return if $MASTER eq $_[0];

   snd $port{$MASTER}, "seedme0"
      if $MASTER && node_is_up $MASTER;

   $MASTER = $_[0];

   if ($MASTER) {
      snd $port{$MASTER}, "seedme1";
      $AnyEvent::MP::Kernel::WARN->(7, "selected new master: $MASTER.");
   } else {
      $AnyEvent::MP::Kernel::WARN->(1, "no contact to any other node, cannot seed.");
   }
}

sub mon_node {
   my ($node, $is_up) = @_;

   if ($is_up) {
      ++$nodecnt;
      start_node $node;

      if (node_is_seed $node) {
         if (node_is_seed $MASTER) {
            my @SEEDS = up_seeds;

            # switching here with lower chance roughly hopefully still gives us
            # an equal selection.
            set_master $node
               if 1 < rand @SEEDS;
         } else {
            # a seed always beats a non-seed
            set_master $node;
         }
      }
   }

   # select a new(?) master, if required
   unless ($MASTER and node_is_up $MASTER) {
      if (my @SEEDS = up_seeds) {
         set_master $SEEDS[rand @SEEDS];
      } else {
         # select "last" non-seed node
         set_master +(sort +up_nodes)[-1];
      }
   }

   unless ($is_up) {
      --$nodecnt;
      more_seeding unless $nodecnt;
      unreg_groups $node;

      # forget about the node
      delete $addr{$node};

      # ask our master for quick recovery
      snd $port{$MASTER}, find => $node
         if $MASTER;
   }
}

mon_node $_, 1
   for up_nodes;

mon_nodes \&mon_node;

=back

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

