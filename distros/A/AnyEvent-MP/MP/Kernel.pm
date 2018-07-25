=head1 NAME

AnyEvent::MP::Kernel - the actual message passing kernel

=head1 SYNOPSIS

   use AnyEvent::MP::Kernel;

   $AnyEvent::MP::Kernel::SRCNODE   # contains msg origin node id, for debugging

   snd_to_func $node, $func, @args  # send msg to function
   snd_on $node, @msg               # snd message again (relay)
   eval_on $node, $string[, @reply] # execute perl code on another node

   node_is_up $nodeid               # return true if a node is connected
   @nodes = up_nodes                # return a list of all connected nodes
   $guard = mon_nodes $callback->($node, $is_up, @reason) # connections up/downs

=head1 DESCRIPTION

This module implements most of the inner workings of AnyEvent::MP. It
offers mostly lower-level functions that deal with network connectivity
and special requests.

You normally interface with AnyEvent::MP through a higher level interface
such as L<AnyEvent::MP> and L<Coro::MP>, although there is nothing wrong
with using the functions from this module.

=head1 GLOBALS AND FUNCTIONS

=over 4

=cut

package AnyEvent::MP::Kernel;

use common::sense;
use Carp ();

use AnyEvent ();
use Guard ();

use AnyEvent::MP::Node;
use AnyEvent::MP::Transport;

use base "Exporter";

# for re-export in AnyEvent::MP and Coro::MP
our @EXPORT_API = qw(
   NODE $NODE
   configure
   node_of port_is_local
   snd kil
   db_set db_del
   db_mon db_family db_keys db_values
);

our @EXPORT_OK = (
   # these are internal
   qw(
      %NODE %PORT %PORT_DATA $UNIQ $RUNIQ $ID
      add_node load_func
   ),
   @EXPORT_API,
);

our @EXPORT = qw(
   snd_to_func snd_on eval_on
   port_is_local
   up_nodes mon_nodes node_is_up
);

our @CARP_NOT = (AnyEvent::MP::);

sub load_func($) {
   my $func = $_[0];

   unless (defined &$func) {
      my $pkg = $func;
      do {
         $pkg =~ s/::[^:]+$//
            or return sub { die "unable to resolve function '$func'" };

         local $@;
         unless (eval "require $pkg; 1") {
            my $error = $@;
            $error =~ /^Can't locate .*.pm in \@INC \(/
               or return sub { die $error };
         }
      } until defined &$func;
   }

   \&$func
}

my @alnum = ('0' .. '9', 'A' .. 'Z', 'a' .. 'z');

sub nonce($) {
   join "", map chr rand 256, 1 .. $_[0]
}

sub nonce62($) {
   join "", map $alnum[rand 62], 1 .. $_[0]
}

our $CONFIG; # this node's configuration
our $SECURE;

our $RUNIQ; # remote uniq value
our $UNIQ;  # per-process/node unique cookie
our $NODE;
our $ID = "a";

our %NODE; # node id to transport mapping, or "undef", for local node
our (%PORT, %PORT_DATA); # local ports

our %RMON; # local ports monitored by remote nodes ($RMON{nodeid}{portid} == cb)
our %LMON; # monitored _local_ ports

#our $GLOBAL; # true if node is a global ("directory") node
our %BINDS;
our $BINDS; # our listeners, as arrayref

our $SRCNODE; # holds the sending node _object_ during _inject
our $GLOBAL;  # true when this is a global node (only set by AnyEvent::MP::Global)

# initialise names for non-networked operation
{
   # ~54 bits, for local port names, lowercase $ID appended
   my $now = AE::now;
   $UNIQ =
      (join "",
         map $alnum[$_],
            $$ / 62 % 62,
            $$ % 62,
            (int $now        ) % 62,
            (int $now *   100) % 62,
            (int $now * 10000) % 62,
      ) . nonce62 4
   ;

   # ~59 bits, for remote port names, one longer than $UNIQ and uppercase at the end to avoid clashes
   $RUNIQ = nonce62 10;
   $RUNIQ =~ s/(.)$/\U$1/;

   $NODE = "";
}

sub NODE() {
   $NODE
}

sub node_of($) {
   my ($node, undef) = split /#/, $_[0], 2;

   $node
}

BEGIN {
   *TRACE = $ENV{PERL_ANYEVENT_MP_TRACE}
      ? sub () { 1 }
      : sub () { 0 };
}

our $DELAY_TIMER;
our @DELAY_QUEUE;

our $delay_run = sub {
   (shift @DELAY_QUEUE or return undef $DELAY_TIMER)->() while 1;
};

sub delay($) {
   push @DELAY_QUEUE, shift;
   $DELAY_TIMER ||= AE::timer 0, 0, $delay_run;
}

=item $AnyEvent::MP::Kernel::SRCNODE

During execution of a message callback, this variable contains the node ID
of the origin node.

The main use of this variable is for debugging output - there are probably
very few other cases where you need to know the source node ID.

=cut

sub _inject {
   warn "RCV $SRCNODE -> " . eval { JSON::XS->new->encode (\@_) } . "\n" if TRACE && @_;

   &{ $PORT{+shift} or return };
}

# this function adds a node-ref, so you can send stuff to it
# it is basically the central routing component.
sub add_node {
   $NODE{$_[0]} || do {
      my ($node) = @_;

      length $node
         or Carp::croak "'undef' or the empty string are not valid node/port IDs";

      # registers itself in %NODE
      new AnyEvent::MP::Node::Remote $node
   }
}

sub snd(@) {
   my ($nodeid, $portid) = split /#/, shift, 2;

   warn "SND $nodeid <- " . eval { JSON::XS->new->encode ([$portid, @_]) } . "\n" if TRACE && @_;

   ($NODE{$nodeid} || add_node $nodeid)
      ->{send} (["$portid", @_]);
}

sub port_is_local($) {
   my ($nodeid, undef) = split /#/, $_[0], 2;

   $nodeid eq $NODE
}

=item snd_to_func $node, $func, @args

Expects a node ID and a name of a function. Asynchronously tries to call
this function with the given arguments on that node.

This function can be used to implement C<spawn>-like interfaces.

=cut

sub snd_to_func($$;@) {
   my $nodeid = shift;

   # on $NODE, we artificially delay... (for spawn)
   # this is very ugly - maybe we should simply delay ALL messages,
   # to avoid deep recursion issues. but that's so... slow...
   $AnyEvent::MP::Node::Self::DELAY = 1
      if $nodeid ne $NODE;

   ($NODE{$nodeid} || add_node $nodeid)->{send} (["", @_]);
}

=item snd_on $node, @msg

Executes C<snd> with the given C<@msg> (which must include the destination
port) on the given node.

=cut

sub snd_on($@) {
   my $node = shift;
   snd $node, snd => @_;
}

=item eval_on $node, $string[, @reply]

Evaluates the given string as Perl expression on the given node. When
@reply is specified, then it is used to construct a reply message with
C<"$@"> and any results from the eval appended.

=cut

sub eval_on($$;@) {
   my $node = shift;
   snd $node, eval => @_;
}

sub kil(@) {
   my ($nodeid, $portid) = split /#/, shift, 2;

   length $portid
      or Carp::croak "$nodeid#$portid: killing a node port is not allowed, caught";

   ($NODE{$nodeid} || add_node $nodeid)
      ->kill ("$portid", @_);
}

#############################################################################
# node monitoring and info

=item $bool = node_is_up $nodeid

Returns true if the given node is "up", that is, the kernel thinks it has
a working connection to it.

More precisely, if the node is up, returns C<1>. If the node is currently
connecting or otherwise known but not connected, returns C<0>. If nothing
is known about the node, returns C<undef>.

=cut

sub node_is_up($) {
   ($_[0] eq $NODE) || ($NODE{$_[0]} or return)->{transport}
      ? 1 : 0
}

=item @nodes = up_nodes

Return the node IDs of all nodes that are currently connected (excluding
the node itself).

=cut

sub up_nodes() {
   map $_->{id}, grep $_->{transport}, values %NODE
}

=item $guard = mon_nodes $callback->($nodeid, $is_up, @reason)

Registers a callback that is called each time a node goes up (a connection
is established) or down (the connection is lost).

Node up messages can only be followed by node down messages for the same
node, and vice versa.

Note that monitoring a node is usually better done by monitoring its node
port. This function is mainly of interest to modules that are concerned
about the network topology and low-level connection handling.

Callbacks I<must not> block and I<should not> send any messages.

The function returns an optional guard which can be used to unregister
the monitoring callback again.

Example: make sure you call function C<newnode> for all nodes that are up
or go up (and down).

   newnode $_, 1 for up_nodes;
   mon_nodes \&newnode;

=cut

our %MON_NODES;

sub mon_nodes($) {
   my ($cb) = @_;

   $MON_NODES{$cb+0} = $cb;

   defined wantarray
      and Guard::guard { delete $MON_NODES{$cb+0} }
}

sub _inject_nodeevent($$;@) {
   my ($node, $up, @reason) = @_;

   AE::log 7 => "$node->{id} is " . ($up ? "up." : "down (@reason).");

   for my $cb (values %MON_NODES) {
      eval { $cb->($node->{id}, $up, @reason); 1 }
         or AE::log die => $@;
   }
}

#############################################################################
# self node code

sub _kill {
   my $port = shift;

   delete $PORT{$port}
      or return; # killing nonexistent ports is O.K.
   delete $PORT_DATA{$port};

   my $mon = delete $LMON{$port}
      or !@_
      or AE::log die => "unmonitored local port $port died with reason: @_";

   $_->(@_) for values %$mon;
}

sub _monitor {
   return $_[2](no_such_port => "cannot monitor nonexistent port", "$NODE#$_[1]")
      unless exists $PORT{$_[1]};

   $LMON{$_[1]}{$_[2]+0} = $_[2];
}

sub _unmonitor {
   delete $LMON{$_[1]}{$_[2]+0}
      if exists $LMON{$_[1]};
}

sub _secure_check {
   $SECURE
      and die "remote execution not allowed\n";
}

our %NODE_REQ;

%NODE_REQ = (
   # "mproto" - monitoring protocol

   # monitoring
   mon0 => sub { # stop monitoring a port for another node
      my $portid = shift;
      # the if exists should not be needed, but there is apparently a bug
      # elsewhere, and this works around that, silently suppressing that bug. sigh.
      _unmonitor undef, $portid, delete $NODE{$SRCNODE}{rmon}{$portid}
         if exists $NODE{$SRCNODE};
   },
   mon1 => sub { # start monitoring a port for another node
      my $portid = shift;
      Scalar::Util::weaken (my $node = $NODE{$SRCNODE});
      _monitor undef, $portid, $node->{rmon}{$portid} = sub {
         delete $node->{rmon}{$portid};
         $node->send (["", kil0 => $portid, @_])
            if $node && $node->{transport};
      };
   },
   # another node has killed a monitored port
   kil0 => sub {
      my $cbs = delete $NODE{$SRCNODE}{lmon}{+shift}
         or return;

      $_->(@_) for @$cbs;
   },
   # another node wants to kill a local port
   kil1 => \&_kill,

   # "public" services - not actually public

   # relay message to another node / generic echo
   snd => sub {
      &snd
   },
   # ask if a node supports the given request, only works for fixed tags
   can => sub {
      my $method = shift;
      snd @_, exists $NODE_REQ{$method};
   },

   # random utilities
   eval => sub {
      &_secure_check;
      my @res = do { package main; eval shift };
      snd @_, "$@", @res if @_;
   },
   time => sub {
      snd @_, AE::now;
   },
   devnull => sub {
      #
   },
   "" => sub {
      # empty messages are keepalives or similar devnull-applications
   },
);

# the node port
new AnyEvent::MP::Node::Self $NODE; # registers itself in %NODE

$PORT{""} = sub {
   my $tag = shift;
   eval { &{ $NODE_REQ{$tag} ||= do { &_secure_check; load_func $tag } } };
   AE::log die => "error processing node message from $SRCNODE: $@" if $@;
};

our $MPROTO = 1;

# tell everybody who connects our nproto
push @AnyEvent::MP::Transport::HOOK_GREET, sub {
   $_[0]{local_greeting}{mproto} = $MPROTO;
};

#############################################################################
# seed management, try to keep connections to all seeds at all times

our %SEED_NODE;    # seed ID => node ID|undef
our %NODE_SEED;    # map node ID to seed ID
our %SEED_CONNECT; # $seed => transport_connector | 1=connected | 2=connecting
our $SEED_WATCHER;
our $SEED_RETRY;
our %GLOBAL_NODE;  # global => undef

sub seed_connect {
   my ($seed) = @_;

   my ($host, $port) = AnyEvent::Socket::parse_hostport $seed
      or Carp::croak "$seed: unparsable seed address";

   AE::log 9 => "trying connect to seed node $seed.";

   $SEED_CONNECT{$seed} ||= AnyEvent::MP::Transport::mp_connect
      $host, $port,
      on_greeted => sub {
         # called after receiving remote greeting, learn remote node name

         # we rely on untrusted data here (the remote node name) this is
         # hopefully ok, as this can at most be used for DOSing, which is easy
         # when you can do MITM anyway.

         # if we connect to ourselves, nuke this seed, but make sure we act like a seed
         if ($_[0]{remote_node} eq $AnyEvent::MP::Kernel::NODE) {
            require AnyEvent::MP::Global; # every seed becomes a global node currently
            delete $SEED_NODE{$seed};
         } else {
            $SEED_NODE{$seed} = $_[0]{remote_node};
            $NODE_SEED{$_[0]{remote_node}} = $seed;

            # also start global service, in case it isn't running
            # since we probably switch conenctions, maybe we don't need to do this here?
            snd $_[0]{remote_node}, "g_slave";
         }
      },
      sub {
         delete $SEED_CONNECT{$seed};
      }
   ;
}

sub seed_all {
   my @seeds = grep
      !(defined $SEED_NODE{$_} && node_is_up $SEED_NODE{$_}),
      keys %SEED_NODE;

   if (@seeds) {
      # start connection attempt for every seed we are not connected to yet
      seed_connect $_
         for grep !exists $SEED_CONNECT{$_}, @seeds;

      $SEED_RETRY = $SEED_RETRY * 2;
      $SEED_RETRY = $AnyEvent::MP::Kernel::CONFIG->{monitor_timeout}
         if $SEED_RETRY > $AnyEvent::MP::Kernel::CONFIG->{monitor_timeout};

      $SEED_WATCHER = AE::timer $SEED_RETRY, 0, \&seed_all;

   } else {
      # all seeds connected or connecting, no need to restart timer
      undef $SEED_WATCHER;
   }
}

sub seed_again {
   $SEED_RETRY = (1 + rand) * 0.6;
   $SEED_WATCHER ||= AE::timer 0, 0, \&seed_all;
}

# sets new seed list, starts connecting
sub set_seeds(@) {
   %SEED_NODE     = ();
   %NODE_SEED     = ();
   %SEED_CONNECT  = ();

   @SEED_NODE{@_} = ();

   seed_again;
}

# normal nodes only record global node connections
$NODE_REQ{g_global} = sub {
   undef $GLOBAL_NODE{$SRCNODE};
};

mon_nodes sub {
   delete $GLOBAL_NODE{$_[0]}
     unless $_[1];

   return unless exists $NODE_SEED{$_[0]};

   if ($_[1]) {
      # each time a connection to a seed node goes up, make
      # sure it runs the global service.
      snd $_[0], "g_slave";
   } else {
      # if we lost the connection to a seed node, make sure we are seeding
      seed_again;
   }
};

#############################################################################
# keepalive code - used to kepe conenctions to certain nodes alive
# only used by global code atm., but ought to be exposed somehow.
#TODO: should probbaly be done directly by node objects

our $KEEPALIVE_RETRY;
our $KEEPALIVE_WATCHER;
our %KEEPALIVE; # we want to keep these nodes alive
our %KEEPALIVE_DOWN; # nodes that are down currently

sub keepalive_all {
   AE::log 9 => "keepalive: trying to establish connections with: "
                . (join " ", keys %KEEPALIVE_DOWN)
                . ".";

   (add_node $_)->connect
      for keys %KEEPALIVE_DOWN;

   $KEEPALIVE_RETRY = $KEEPALIVE_RETRY * 2;
   $KEEPALIVE_RETRY = $AnyEvent::MP::Kernel::CONFIG->{monitor_timeout}
      if $KEEPALIVE_RETRY > $AnyEvent::MP::Kernel::CONFIG->{monitor_timeout};

   $KEEPALIVE_WATCHER = AE::timer $KEEPALIVE_RETRY, 0, \&keepalive_all;
}

sub keepalive_again {
   $KEEPALIVE_RETRY = (1 + rand) * 0.3;
   keepalive_all;
}

sub keepalive_add {
   return if $KEEPALIVE{$_[0]}++;

   return if node_is_up $_[0];
   undef $KEEPALIVE_DOWN{$_[0]};
   keepalive_again;
}

sub keepalive_del {
   return if --$KEEPALIVE{$_[0]};

   delete $KEEPALIVE     {$_[0]};
   delete $KEEPALIVE_DOWN{$_[0]};

   undef $KEEPALIVE_WATCHER
      unless %KEEPALIVE_DOWN;
}

mon_nodes sub {
   return unless exists $KEEPALIVE{$_[0]};

   if ($_[1]) {
      delete $KEEPALIVE_DOWN{$_[0]};

      undef $KEEPALIVE_WATCHER
         unless %KEEPALIVE_DOWN;
   } else {
      # lost the conenction, try to connect again
      undef $KEEPALIVE_DOWN{$_[0]};
      keepalive_again;
   }
};

#############################################################################
# talk with/to global nodes

# protocol messages:
#
# sent by global nodes
# g_global                  - global nodes send this to all others
#
# database protocol
# g_slave database          - make other global node master of the sender
# g_set database            - global node's database to other global nodes
# g_upd family set del      - update single family (any to global)
#
# slave <-> global protocol
# g_find node               - query addresses for node (slave to global)
# g_found node binds        - node addresses (global to slave)
# g_db_family family id     - send g_reply with data (global to slave)
# g_db_keys   family id     - send g_reply with data (global to slave)
# g_db_values family id     - send g_reply with data (global to slave)
# g_reply id result         - result of any query (global to slave)
# g_mon1 family             - start to monitor family, replies with g_chg1
# g_mon0 family             - stop monitoring family
# g_chg1 family hash        - initial value of family when starting to monitor
# g_chg2 family set del     - like g_upd, but for monitoring only
#
# internal database families:
# "'l" -> node -> listeners
# "'g" -> node -> undef
# ...
#

# used on all nodes:
our $MASTER;       # the global node we bind ourselves to
our $MASTER_MON;
our %LOCAL_DB;     # this node database

our $GPROTO = 1;

# tell everybody who connects our gproto
push @AnyEvent::MP::Transport::HOOK_GREET, sub {
   $_[0]{local_greeting}{gproto} = $GPROTO;
};

#############################################################################
# master selection

# master requests
our %GLOBAL_REQ; # $id => \@req

sub global_req_add {
   my ($id, $req) = @_;

   return if exists $GLOBAL_REQ{$id};

   $GLOBAL_REQ{$id} = $req;

   snd $MASTER, @$req
      if $MASTER;
}

sub global_req_del {
   delete $GLOBAL_REQ{$_[0]};
}

#################################
# master rpc

our %GLOBAL_RES;
our $GLOBAL_RES_ID = "a";

sub global_call {
   my $id = ++$GLOBAL_RES_ID;
   $GLOBAL_RES{$id} = pop;
   global_req_add $id, [@_, $id];
}

$NODE_REQ{g_reply} = sub {
   my $id = shift;
   global_req_del $id;
   my $cb = delete $GLOBAL_RES{$id}
      or return;
   &$cb
};

#################################

sub g_find {
   global_req_add "g_find $_[0]", [g_find => $_[0]];
}

# reply for g_find started in Node.pm
$NODE_REQ{g_found} = sub {
   global_req_del "g_find $_[0]";

   my $node = $NODE{$_[0]} or return;

   $node->connect_to ($_[1]);
};

sub master_set {
   $MASTER = $_[0];
   AE::log 8 => "new master node: $MASTER.";

   $MASTER_MON = mon_nodes sub {
      if ($_[0] eq $MASTER && !$_[1]) {
         undef $MASTER;
         master_search ();
      }
   };

   snd $MASTER, g_slave => \%LOCAL_DB;

   # (re-)send queued requests
   snd $MASTER, @$_
      for values %GLOBAL_REQ;
}

sub master_search {
   AE::log 9 => "starting search for master node.";

   #TODO: should also look for other global nodes, but we don't know them
   for (keys %NODE_SEED) {
      if (node_is_up $_) {
         master_set $_;
         return;
      }
   }

   $MASTER_MON = mon_nodes sub {
      return unless $_[1]; # we are only interested in node-ups
      return unless $NODE_SEED{$_[0]}; # we are only interested in seed nodes

      master_set $_[0];
   };
}

# other node wants to make us the master, so start the global service
$NODE_REQ{g_slave} = sub {
   # load global module and redo the request
   require AnyEvent::MP::Global;
   &{ $NODE_REQ{g_slave} }
};

#############################################################################
# local database operations

# canonical probably not needed
our $sv_eq_coder = JSON::XS->new->utf8->allow_nonref;

# are the two scalars equal? very very ugly and slow, need better way
sub sv_eq($$) {
   ref $_[0] || ref $_[1]
      ? (JSON::XS::encode $sv_eq_coder, $_[0]) eq (JSON::XS::encode $sv_eq_coder, $_[1])
      : $_[0] eq $_[1]
        && defined $_[0] == defined $_[1]
}

# local database management

sub db_del($@) {
   my $family = shift;

   my @del = grep exists $LOCAL_DB{$family}{$_}, @_;

   return unless @del;

   delete @{ $LOCAL_DB{$family} }{@del};
   snd $MASTER, g_upd => $family => undef, \@del
      if defined $MASTER;
}

sub db_set($$;$) {
   my ($family, $subkey) = @_;

#   if (ref $_[1]) {
#      # bulk
#      my @del = grep exists $LOCAL_DB{$_[0]}{$_}, keys ${ $_[1] };
#      $LOCAL_DB{$_[0]} = $_[1];
#      snd $MASTER, g_upd => $_[0] => $_[1], \@del
#         if defined $MASTER;
#   } else {
      # single-key
      unless (exists $LOCAL_DB{$family}{$subkey} && sv_eq $LOCAL_DB{$family}{$subkey}, $_[2]) {
         $LOCAL_DB{$family}{$subkey} = $_[2];
         snd $MASTER, g_upd => $family => { $subkey => $_[2] }
            if defined $MASTER;
      }
#   }

   defined wantarray
      and Guard::guard { db_del $family => $subkey }
}

# database query

sub db_family {
   my ($family, $cb) = @_;
   global_call g_db_family => $family, $cb;
}

sub db_keys {
   my ($family, $cb) = @_;
   global_call g_db_keys   => $family, $cb;
}

sub db_values {
   my ($family, $cb) = @_;
   global_call g_db_values => $family, $cb;
}

# database monitoring

our %LOCAL_MON; # f, reply
our %MON_DB;    # f, k, value

sub db_mon($@) {
   my ($family, $cb) = @_;

   if (my $db = $MON_DB{$family}) {
      # we already monitor, so create a "dummy" change event
      # this is postponed, which might be too late (we could process
      # change events), so disable the callback at first
      $LOCAL_MON{$family}{$cb+0} = sub { };
      AE::postpone {
         return unless exists $LOCAL_MON{$family}{$cb+0}; # guard might have gone away already

         # set actual callback
         $LOCAL_MON{$family}{$cb+0} = $cb;
         $cb->($db, [keys %$db]);
      };
   } else {
      # new monitor, request chg1 from upstream
      $LOCAL_MON{$family}{$cb+0} = $cb;
      global_req_add "mon1 $family" => [g_mon1 => $family];
      $MON_DB{$family} = {};
   }

   defined wantarray
      and Guard::guard {
         my $mon = $LOCAL_MON{$family};
         delete $mon->{$cb+0};

         unless (%$mon) {
            global_req_del "mon1 $family";

            # no global_req, because we don't care if we are not connected
            snd $MASTER, g_mon0 => $family
               if $MASTER;

            delete $LOCAL_MON{$family};
            delete $MON_DB{$family};
         }
      }
}

# full update
$NODE_REQ{g_chg1} = sub {
   return unless $SRCNODE eq $MASTER;
   my ($f, $ndb) = @_;

   my $db = $MON_DB{$f};
   my (@a, @c, @d);

   # add or replace keys
   while (my ($k, $v) = each %$ndb) {
      exists $db->{$k}
         ? push @c, $k
         : push @a, $k;
      $db->{$k} = $v;
   }

   # delete keys that are no longer present
   for (grep !exists $ndb->{$_}, keys %$db) {
      delete $db->{$_};
      push @d, $_;
   }

   $_->($db, \@a, \@c, \@d)
      for values %{ $LOCAL_MON{$_[0]} };
};

# incremental update
$NODE_REQ{g_chg2} = sub {
   return unless $SRCNODE eq $MASTER;
   my ($family, $set, $del) = @_;

   my $db = $MON_DB{$family};

   my (@a, @c);

   while (my ($k, $v) = each %$set) {
      exists $db->{$k}
         ? push @c, $k
         : push @a, $k;
      $db->{$k} = $v;
   }

   delete @$db{@$del};

   $_->($db, \@a, \@c, $del)
      for values %{ $LOCAL_MON{$family} };
};

#############################################################################
# configure

sub nodename {
   require POSIX;
   (POSIX::uname ())[1]
}

sub _resolve($) {
   my ($nodeid) = @_;

   my $cv = AE::cv;
   my @res;

   $cv->begin (sub {
      my %seen;
      my @refs;
      for (sort { $a->[0] <=> $b->[0] } @res) {
         push @refs, $_->[1] unless $seen{$_->[1]}++
      }
      shift->send (@refs);
   });

   my $idx;
   for my $t (split /,/, $nodeid) {
      my $pri = ++$idx;

      $t = length $t ? nodename . ":$t" : nodename
         if $t =~ /^\d*$/;
      
      my ($host, $port) = AnyEvent::Socket::parse_hostport $t, 0
         or Carp::croak "$t: unparsable transport descriptor";

      $port = "0" if $port eq "*";

      if ($host eq "*") {
         $cv->begin;

         my $get_addr = sub {
            my @addr;

            require Net::Interface;

            # Net::Interface hangs on some systems, so hope for the best
            local $SIG{ALRM} = 'DEFAULT';
            alarm 2;

            for my $if (Net::Interface->interfaces) {
               # we statically lower-prioritise ipv6 here, TODO :()
               for $_ ($if->address (Net::Interface::AF_INET ())) {
                  next if /^\x7f/; # skip localhost etc.
                  push @addr, $_;
               }
               for ($if->address (Net::Interface::AF_INET6 ())) {
                  #next if $if->scope ($_) <= 2;
                  next unless /^[\x20-\x3f\xfc\xfd]/; # global unicast, site-local unicast
                  push @addr, $_;
               }
            }

            alarm 0;

            @addr
         };

         my @addr;

         if (AnyEvent::WIN32) {
            @addr = $get_addr->();
         } else {
            # use a child process, as Net::Interface is big, and we need it only once.

            pipe my $r, my $w
               or die "pipe: $!";

            if (fork eq 0) {
               close $r;
               syswrite $w, pack "(C/a*)*", $get_addr->();
               require POSIX;
               POSIX::_exit (0);
            } else {
               close $w;

               my $addr;

               1 while sysread $r, $addr, 1024, length $addr;
               
               @addr = unpack "(C/a*)*", $addr;
            }
         }

         for my $ip (@addr) {
            push @res, [
               $pri += 1e-5,
               AnyEvent::Socket::format_hostport AnyEvent::Socket::format_address $ip, $port
            ];
         }
         $cv->end;
      } else {
         $cv->begin;
         AnyEvent::Socket::resolve_sockaddr $host, $port, "tcp", 0, undef, sub {
            for (@_) {
               my ($service, $host) = AnyEvent::Socket::unpack_sockaddr $_->[3];
               push @res, [
                  $pri += 1e-5,
                  AnyEvent::Socket::format_hostport AnyEvent::Socket::format_address $host, $service
               ];
            }
            $cv->end;
         };
      }
   }

   $cv->end;

   $cv
}

our @POST_CONFIGURE;

# not yet documented
sub post_configure(&) {
   die "AnyEvent::MP::Kernel::post_configure must be called in void context" if defined wantarray;

   push @POST_CONFIGURE, @_;
   (shift @POST_CONFIGURE)->() while $NODE && @POST_CONFIGURE;
}

sub configure(@) {
   unshift @_, "profile" if @_ & 1;
   my (%kv) = @_;

   my $profile = delete $kv{profile};

   $profile = nodename
      unless defined $profile;

   $CONFIG = AnyEvent::MP::Config::find_profile $profile, %kv;

   $SECURE = $CONFIG->{secure};

   my $node = exists $CONFIG->{nodeid} ? $CONFIG->{nodeid} : "$profile/";

   $node or Carp::croak "$node: illegal node ID (see AnyEvent::MP manpage for syntax)\n";

   my $node_obj = delete $NODE{$NODE}; # we do not support doing stuff before configure

   $NODE = $node;

   $NODE =~ s/%n/nodename/ge;

   if ($NODE =~ s!(?:(?<=/)$|%u)!$RUNIQ!g) {
      # nodes with randomised node names do not need randomised port names
      $UNIQ = "";
   }

   $node_obj->{id} = $NODE;
   $NODE{$NODE} = $node_obj;

   my $seeds = $CONFIG->{seeds};
   my $binds = $CONFIG->{binds};

   $binds ||= ["*"];

   AE::log 8 => "node $NODE starting up.";

   $BINDS = [];
   %BINDS = ();

   for (map _resolve $_, @$binds) {
      for my $bind ($_->recv) {
         my ($host, $port) = AnyEvent::Socket::parse_hostport $bind
            or Carp::croak "$bind: unparsable local bind address";

         my $listener = AnyEvent::MP::Transport::mp_server
            $host,
            $port,
            prepare => sub {
               my (undef, $host, $port) = @_;
               $bind = AnyEvent::Socket::format_hostport $host, $port;
               0
            },
         ;
         $BINDS{$bind} = $listener;
         push @$BINDS, $bind;
      }
   }

   AE::log 9 => "running post config hooks and init.";

   # might initialise Global, so need to do it before db_set
   post_configure { };

   db_set "'l" => $NODE => $BINDS;

   AE::log 8 => "node listens on [@$BINDS].";

   # connect to all seednodes
   set_seeds map $_->recv, map _resolve $_, @$seeds;
   master_search;

   # save gobs of memory
   undef &_resolve;
   *configure = sub (@){ };

   AE::log 9 => "starting services.";

   for (@{ $CONFIG->{services} }) {
      if (ref) {
         my ($func, @args) = @$_;
         (load_func $func)->(@args);
      } elsif (s/::$//) {
         eval "require $_";
         die $@ if $@;
      } else {
         (load_func $_)->();
      }
   }

   eval "#line 1 \"(eval configure parameter)\"\n$CONFIG->{eval}";
   die "$@" if $@;
}

=back

=head1 LOGGING

AnyEvent::MP::Kernel logs high-level information about the current node,
when nodes go up and down, and most runtime errors. It also logs some
debugging and trace messages about network maintainance, such as seed
connections and global node management.

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

