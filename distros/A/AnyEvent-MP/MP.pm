=head1 NAME

AnyEvent::MP - erlang-style multi-processing/message-passing framework

=head1 SYNOPSIS

   use AnyEvent::MP;

   $NODE      # contains this node's node ID
   NODE       # returns this node's node ID

   $SELF      # receiving/own port id in rcv callbacks

   # initialise the node so it can send/receive messages
   configure;

   # ports are message destinations

   # sending messages
   snd $port, type => data...;
   snd $port, @msg;
   snd @msg_with_first_element_being_a_port;

   # creating/using ports, the simple way
   my $simple_port = port { my @msg = @_ };

   # creating/using ports, tagged message matching
   my $port = port;
   rcv $port, ping => sub { snd $_[0], "pong" };
   rcv $port, pong => sub { warn "pong received\n" };

   # create a port on another node
   my $port = spawn $node, $initfunc, @initdata;

   # destroy a port again
   kil $port;  # "normal" kill
   kil $port, my_error => "everything is broken"; # error kill

   # monitoring
   mon $port, $cb->(@msg)      # callback is invoked on death
   mon $port, $localport       # kill localport on abnormal death
   mon $port, $localport, @msg # send message on death

   # temporarily execute code in port context
   peval $port, sub { die "kill the port!" };

   # execute callbacks in $SELF port context
   my $timer = AE::timer 1, 0, psub {
      die "kill the port, delayed";
   };

   # distributed database - modification
   db_set $family => $subkey [=> $value]  # add a subkey
   db_del $family => $subkey...           # delete one or more subkeys
   db_reg $family => $port [=> $value]    # register a port

   # distributed database - queries
   db_family $family => $cb->(\%familyhash)
   db_keys   $family => $cb->(\@keys)
   db_values $family => $cb->(\@values)

   # distributed database - monitoring a family
   db_mon $family => $cb->(\%familyhash, \@added, \@changed, \@deleted)

=head1 DESCRIPTION

This module (-family) implements a simple message passing framework.

Despite its simplicity, you can securely message other processes running
on the same or other hosts, and you can supervise entities remotely.

For an introduction to this module family, see the L<AnyEvent::MP::Intro>
manual page and the examples under F<eg/>.

=head1 CONCEPTS

=over 4

=item port

Not to be confused with a TCP port, a "port" is something you can send
messages to (with the C<snd> function).

Ports allow you to register C<rcv> handlers that can match all or just
some messages. Messages send to ports will not be queued, regardless of
anything was listening for them or not.

Ports are represented by (printable) strings called "port IDs".

=item port ID - C<nodeid#portname>

A port ID is the concatenation of a node ID, a hash-mark (C<#>)
as separator, and a port name (a printable string of unspecified
format created by AnyEvent::MP).

=item node

A node is a single process containing at least one port - the node port,
which enables nodes to manage each other remotely, and to create new
ports.

Nodes are either public (have one or more listening ports) or private
(no listening ports). Private nodes cannot talk to other private nodes
currently, but all nodes can talk to public nodes.

Nodes is represented by (printable) strings called "node IDs".

=item node ID - C<[A-Za-z0-9_\-.:]*>

A node ID is a string that uniquely identifies the node within a
network. Depending on the configuration used, node IDs can look like a
hostname, a hostname and a port, or a random string. AnyEvent::MP itself
doesn't interpret node IDs in any way except to uniquely identify a node.

=item binds - C<ip:port>

Nodes can only talk to each other by creating some kind of connection to
each other. To do this, nodes should listen on one or more local transport
endpoints - binds.

Currently, only standard C<ip:port> specifications can be used, which
specify TCP ports to listen on. So a bind is basically just a tcp socket
in listening mode that accepts connections from other nodes.

=item seed nodes

When a node starts, it knows nothing about the network it is in - it
needs to connect to at least one other node that is already in the
network. These other nodes are called "seed nodes".

Seed nodes themselves are not special - they are seed nodes only because
some other node I<uses> them as such, but any node can be used as seed
node for other nodes, and eahc node can use a different set of seed nodes.

In addition to discovering the network, seed nodes are also used to
maintain the network - all nodes using the same seed node are part of the
same network. If a network is split into multiple subnets because e.g. the
network link between the parts goes down, then using the same seed nodes
for all nodes ensures that eventually the subnets get merged again.

Seed nodes are expected to be long-running, and at least one seed node
should always be available. They should also be relatively responsive - a
seed node that blocks for long periods will slow down everybody else.

For small networks, it's best if every node uses the same set of seed
nodes. For large networks, it can be useful to specify "regional" seed
nodes for most nodes in an area, and use all seed nodes as seed nodes for
each other. What's important is that all seed nodes connections form a
complete graph, so that the network cannot split into separate subnets
forever.

Seed nodes are represented by seed IDs.

=item seed IDs - C<host:port>

Seed IDs are transport endpoint(s) (usually a hostname/IP address and a
TCP port) of nodes that should be used as seed nodes.

=item global nodes

An AEMP network needs a discovery service - nodes need to know how to
connect to other nodes they only know by name. In addition, AEMP offers a
distributed "group database", which maps group names to a list of strings
- for example, to register worker ports.

A network needs at least one global node to work, and allows every node to
be a global node.

Any node that loads the L<AnyEvent::MP::Global> module becomes a global
node and tries to keep connections to all other nodes. So while it can
make sense to make every node "global" in small networks, it usually makes
sense to only make seed nodes into global nodes in large networks (nodes
keep connections to seed nodes and global nodes, so making them the same
reduces overhead).

=back

=head1 VARIABLES/FUNCTIONS

=over 4

=cut

package AnyEvent::MP;

use AnyEvent::MP::Config ();
use AnyEvent::MP::Kernel;
use AnyEvent::MP::Kernel qw(
   %NODE %PORT %PORT_DATA $UNIQ $RUNIQ $ID
   add_node load_func

   NODE $NODE
   configure
   node_of port_is_local
   snd kil
   db_set db_del
   db_mon db_family db_keys db_values
);

use common::sense;

use Carp ();

use AnyEvent ();
use Guard ();

use base "Exporter";

our $VERSION = '2.02'; # also in MP/Config.pm

our @EXPORT = qw(
   NODE $NODE
   configure
   node_of port_is_local
   snd kil
   db_set db_del
   db_mon db_family db_keys db_values

   *SELF

   port rcv mon mon_guard psub peval spawn cal
   db_set db_del db_reg
   db_mon db_family db_keys db_values

   after
);

our $SELF;

sub _self_die() {
   my $msg = $@;
   $msg =~ s/\n+$// unless ref $msg;
   kil $SELF, die => $msg;
}

=item $thisnode = NODE / $NODE

The C<NODE> function returns, and the C<$NODE> variable contains, the node
ID of the node running in the current process. This value is initialised by
a call to C<configure>.

=item $nodeid = node_of $port

Extracts and returns the node ID from a port ID or a node ID.

=item $is_local = port_is_local $port

Returns true iff the port is a local port.

=item configure $profile, key => value...

=item configure key => value...

Before a node can talk to other nodes on the network (i.e. enter
"distributed mode") it has to configure itself - the minimum a node needs
to know is its own name, and optionally it should know the addresses of
some other nodes in the network to discover other nodes.

This function configures a node - it must be called exactly once (or
never) before calling other AnyEvent::MP functions.

The key/value pairs are basically the same ones as documented for the
F<aemp> command line utility (sans the set/del prefix), with these additions:

=over 4

=item norc => $boolean (default false)

If true, then the rc file (e.g. F<~/.perl-anyevent-mp>) will I<not>
be consulted - all configuration options must be specified in the
C<configure> call.

=item force => $boolean (default false)

IF true, then the values specified in the C<configure> will take
precedence over any values configured via the rc file. The default is for
the rc file to override any options specified in the program.

=back

=over 4

=item step 1, gathering configuration from profiles

The function first looks up a profile in the aemp configuration (see the
L<aemp> commandline utility). The profile name can be specified via the
named C<profile> parameter or can simply be the first parameter). If it is
missing, then the nodename (F<uname -n>) will be used as profile name.

The profile data is then gathered as follows:

First, all remaining key => value pairs (all of which are conveniently
undocumented at the moment) will be interpreted as configuration
data. Then they will be overwritten by any values specified in the global
default configuration (see the F<aemp> utility), then the chain of
profiles chosen by the profile name (and any C<parent> attributes).

That means that the values specified in the profile have highest priority
and the values specified directly via C<configure> have lowest priority,
and can only be used to specify defaults.

If the profile specifies a node ID, then this will become the node ID of
this process. If not, then the profile name will be used as node ID, with
a unique randoms tring (C</%u>) appended.

The node ID can contain some C<%> sequences that are expanded: C<%n>
is expanded to the local nodename, C<%u> is replaced by a random
strign to make the node unique. For example, the F<aemp> commandline
utility uses C<aemp/%n/%u> as nodename, which might expand to
C<aemp/cerebro/ZQDGSIkRhEZQDGSIkRhE>.

=item step 2, bind listener sockets

The next step is to look up the binds in the profile, followed by binding
aemp protocol listeners on all binds specified (it is possible and valid
to have no binds, meaning that the node cannot be contacted from the
outside. This means the node cannot talk to other nodes that also have no
binds, but it can still talk to all "normal" nodes).

If the profile does not specify a binds list, then a default of C<*> is
used, meaning the node will bind on a dynamically-assigned port on every
local IP address it finds.

=item step 3, connect to seed nodes

As the last step, the seed ID list from the profile is passed to the
L<AnyEvent::MP::Global> module, which will then use it to keep
connectivity with at least one node at any point in time.

=back

Example: become a distributed node using the local node name as profile.
This should be the most common form of invocation for "daemon"-type nodes.

   configure

Example: become a semi-anonymous node. This form is often used for
commandline clients.

   configure nodeid => "myscript/%n/%u";

Example: configure a node using a profile called seed, which is suitable
for a seed node as it binds on all local addresses on a fixed port (4040,
customary for aemp).

   # use the aemp commandline utility
   # aemp profile seed binds '*:4040'

   # then use it
   configure profile => "seed";

   # or simply use aemp from the shell again:
   # aemp run profile seed

   # or provide a nicer-to-remember nodeid
   # aemp run profile seed nodeid "$(hostname)"

=item $SELF

Contains the current port id while executing C<rcv> callbacks or C<psub>
blocks.

=item *SELF, SELF, %SELF, @SELF...

Due to some quirks in how perl exports variables, it is impossible to
just export C<$SELF>, all the symbols named C<SELF> are exported by this
module, but only C<$SELF> is currently used.

=item snd $port, type => @data

=item snd $port, @msg

Send the given message to the given port, which can identify either a
local or a remote port, and must be a port ID.

While the message can be almost anything, it is highly recommended to
use a string as first element (a port ID, or some word that indicates a
request type etc.) and to consist if only simple perl values (scalars,
arrays, hashes) - if you think you need to pass an object, think again.

The message data logically becomes read-only after a call to this
function: modifying any argument (or values referenced by them) is
forbidden, as there can be considerable time between the call to C<snd>
and the time the message is actually being serialised - in fact, it might
never be copied as within the same process it is simply handed to the
receiving port.

The type of data you can transfer depends on the transport protocol: when
JSON is used, then only strings, numbers and arrays and hashes consisting
of those are allowed (no objects). When Storable is used, then anything
that Storable can serialise and deserialise is allowed, and for the local
node, anything can be passed. Best rely only on the common denominator of
these.

=item $local_port = port

Create a new local port object and returns its port ID. Initially it has
no callbacks set and will throw an error when it receives messages.

=item $local_port = port { my @msg = @_ }

Creates a new local port, and returns its ID. Semantically the same as
creating a port and calling C<rcv $port, $callback> on it.

The block will be called for every message received on the port, with the
global variable C<$SELF> set to the port ID. Runtime errors will cause the
port to be C<kil>ed. The message will be passed as-is, no extra argument
(i.e. no port ID) will be passed to the callback.

If you want to stop/destroy the port, simply C<kil> it:

   my $port = port {
      my @msg = @_;
      ...
      kil $SELF;
   };

=cut

sub rcv($@);

my $KILME = sub {
   (my $tag = substr $_[0], 0, 30) =~ s/([^\x20-\x7e])/./g;
   kil $SELF, unhandled_message => "no callback found for message '$tag'";
};

sub port(;&) {
   my $id = $UNIQ . ++$ID;
   my $port = "$NODE#$id";

   rcv $port, shift || $KILME;

   $port
}

=item rcv $local_port, $callback->(@msg)

Replaces the default callback on the specified port. There is no way to
remove the default callback: use C<sub { }> to disable it, or better
C<kil> the port when it is no longer needed.

The global C<$SELF> (exported by this module) contains C<$port> while
executing the callback. Runtime errors during callback execution will
result in the port being C<kil>ed.

The default callback receives all messages not matched by a more specific
C<tag> match.

=item rcv $local_port, tag => $callback->(@msg_without_tag), ...

Register (or replace) callbacks to be called on messages starting with the
given tag on the given port (and return the port), or unregister it (when
C<$callback> is C<$undef> or missing). There can only be one callback
registered for each tag.

The original message will be passed to the callback, after the first
element (the tag) has been removed. The callback will use the same
environment as the default callback (see above).

Example: create a port and bind receivers on it in one go.

  my $port = rcv port,
     msg1 => sub { ... },
     msg2 => sub { ... },
  ;

Example: create a port, bind receivers and send it in a message elsewhere
in one go:

   snd $otherport, reply =>
      rcv port,
         msg1 => sub { ... },
         ...
   ;

Example: temporarily register a rcv callback for a tag matching some port
(e.g. for an rpc reply) and unregister it after a message was received.

   rcv $port, $otherport => sub {
      my @reply = @_;

      rcv $SELF, $otherport;
   };

=cut

sub rcv($@) {
   my $port = shift;
   my ($nodeid, $portid) = split /#/, $port, 2;

   $nodeid eq $NODE
      or Carp::croak "$port: rcv can only be called on local ports, caught";

   while (@_) {
      if (ref $_[0]) {
         if (my $self = $PORT_DATA{$portid}) {
            "AnyEvent::MP::Port" eq ref $self
               or Carp::croak "$port: rcv can only be called on message matching ports, caught";

            $self->[0] = shift;
         } else {
            my $cb = shift;
            $PORT{$portid} = sub {
               local $SELF = $port;
               eval { &$cb }; _self_die if $@;
            };
         }
      } elsif (defined $_[0]) {
         my $self = $PORT_DATA{$portid} ||= do {
            my $self = bless [$PORT{$portid} || sub { }, { }, $port], "AnyEvent::MP::Port";

            $PORT{$portid} = sub {
               local $SELF = $port;

               if (my $cb = $self->[1]{$_[0]}) {
                  shift;
                  eval { &$cb }; _self_die if $@;
               } else {
                  &{ $self->[0] };
               }
            };

            $self
         };

         "AnyEvent::MP::Port" eq ref $self
            or Carp::croak "$port: rcv can only be called on message matching ports, caught";

         my ($tag, $cb) = splice @_, 0, 2;

         if (defined $cb) {
            $self->[1]{$tag} = $cb;
         } else {
            delete $self->[1]{$tag};
         }
      }
   }

   $port
}

=item peval $port, $coderef[, @args]

Evaluates the given C<$codref> within the context of C<$port>, that is,
when the code throws an exception the C<$port> will be killed.

Any remaining args will be passed to the callback. Any return values will
be returned to the caller.

This is useful when you temporarily want to execute code in the context of
a port.

Example: create a port and run some initialisation code in it's context.

   my $port = port { ... };

   peval $port, sub {
      init
         or die "unable to init";
   };

=cut

sub peval($$) {
   local $SELF = shift;
   my $cb = shift;

   if (wantarray) {
      my @res = eval { &$cb };
      _self_die if $@;
      @res
   } else {
      my $res = eval { &$cb };
      _self_die if $@;
      $res
   }
}

=item $closure = psub { BLOCK }

Remembers C<$SELF> and creates a closure out of the BLOCK. When the
closure is executed, sets up the environment in the same way as in C<rcv>
callbacks, i.e. runtime errors will cause the port to get C<kil>ed.

The effect is basically as if it returned C<< sub { peval $SELF, sub {
BLOCK }, @_ } >>.

This is useful when you register callbacks from C<rcv> callbacks:

   rcv delayed_reply => sub {
      my ($delay, @reply) = @_;
      my $timer = AE::timer $delay, 0, psub {
         snd @reply, $SELF;
      };
   };

=cut

sub psub(&) {
   my $cb = shift;

   my $port = $SELF
      or Carp::croak "psub can only be called from within rcv or psub callbacks, not";

   sub {
      local $SELF = $port;

      if (wantarray) {
         my @res = eval { &$cb };
         _self_die if $@;
         @res
      } else {
         my $res = eval { &$cb };
         _self_die if $@;
         $res
      }
   }
}

=item $guard = mon $port, $rcvport          # kill $rcvport when $port dies

=item $guard = mon $port                    # kill $SELF when $port dies

=item $guard = mon $port, $cb->(@reason)    # call $cb when $port dies

=item $guard = mon $port, $rcvport, @msg    # send a message when $port dies

Monitor the given port and do something when the port is killed or
messages to it were lost, and optionally return a guard that can be used
to stop monitoring again.

The first two forms distinguish between "normal" and "abnormal" kil's:

In the first form (another port given), if the C<$port> is C<kil>'ed with
a non-empty reason, the other port (C<$rcvport>) will be kil'ed with the
same reason. That is, on "normal" kil's nothing happens, while under all
other conditions, the other port is killed with the same reason.

The second form (kill self) is the same as the first form, except that
C<$rvport> defaults to C<$SELF>.

The remaining forms don't distinguish between "normal" and "abnormal" kil's
- it's up to the callback or receiver to check whether the C<@reason> is
empty and act accordingly.

In the third form (callback), the callback is simply called with any
number of C<@reason> elements (empty @reason means that the port was deleted
"normally"). Note also that I<< the callback B<must> never die >>, so use
C<eval> if unsure.

In the last form (message), a message of the form C<$rcvport, @msg,
@reason> will be C<snd>.

Monitoring-actions are one-shot: once messages are lost (and a monitoring
alert was raised), they are removed and will not trigger again, even if it
turns out that the port is still alive.

As a rule of thumb, monitoring requests should always monitor a remote
port locally (using a local C<$rcvport> or a callback). The reason is that
kill messages might get lost, just like any other message. Another less
obvious reason is that even monitoring requests can get lost (for example,
when the connection to the other node goes down permanently). When
monitoring a port locally these problems do not exist.

C<mon> effectively guarantees that, in the absence of hardware failures,
after starting the monitor, either all messages sent to the port will
arrive, or the monitoring action will be invoked after possible message
loss has been detected. No messages will be lost "in between" (after
the first lost message no further messages will be received by the
port). After the monitoring action was invoked, further messages might get
delivered again.

Inter-host-connection timeouts and monitoring depend on the transport
used. The only transport currently implemented is TCP, and AnyEvent::MP
relies on TCP to detect node-downs (this can take 10-15 minutes on a
non-idle connection, and usually around two hours for idle connections).

This means that monitoring is good for program errors and cleaning up
stuff eventually, but they are no replacement for a timeout when you need
to ensure some maximum latency.

Example: call a given callback when C<$port> is killed.

   mon $port, sub { warn "port died because of <@_>\n" };

Example: kill ourselves when C<$port> is killed abnormally.

   mon $port;

Example: send us a restart message when another C<$port> is killed.

   mon $port, $self => "restart";

=cut

sub mon {
   my ($nodeid, $port) = split /#/, shift, 2;

   my $node = $NODE{$nodeid} || add_node $nodeid;

   my $cb = @_ ? shift : $SELF || Carp::croak 'mon: called with one argument only, but $SELF not set,';

   unless (ref $cb) {
      if (@_) {
         # send a kill info message
         my (@msg) = ($cb, @_);
         $cb = sub { snd @msg, @_ };
      } else {
         # simply kill other port
         my $port = $cb;
         $cb = sub { kil $port, @_ if @_ };
      }
   }

   $node->monitor ($port, $cb);

   defined wantarray
      and ($cb += 0, Guard::guard { $node->unmonitor ($port, $cb) })
}

=item $guard = mon_guard $port, $ref, $ref...

Monitors the given C<$port> and keeps the passed references. When the port
is killed, the references will be freed.

Optionally returns a guard that will stop the monitoring.

This function is useful when you create e.g. timers or other watchers and
want to free them when the port gets killed (note the use of C<psub>):

  $port->rcv (start => sub {
     my $timer; $timer = mon_guard $port, AE::timer 1, 1, psub {
        undef $timer if 0.9 < rand;
     });
  });

=cut

sub mon_guard {
   my ($port, @refs) = @_;

   #TODO: mon-less form?

   mon $port, sub { 0 && @refs }
}

=item kil $port[, @reason]

Kill the specified port with the given C<@reason>.

If no C<@reason> is specified, then the port is killed "normally" -
monitor callback will be invoked, but the kil will not cause linked ports
(C<mon $mport, $lport> form) to get killed.

If a C<@reason> is specified, then linked ports (C<mon $mport, $lport>
form) get killed with the same reason.

Runtime errors while evaluating C<rcv> callbacks or inside C<psub> blocks
will be reported as reason C<< die => $@ >>.

Transport/communication errors are reported as C<< transport_error =>
$message >>.

Common idioms:

   # silently remove yourself, do not kill linked ports
   kil $SELF;

   # report a failure in some detail
   kil $SELF, failure_mode_1 => "it failed with too high temperature";

   # do not waste much time with killing, just die when something goes wrong
   open my $fh, "<file"
      or die "file: $!";

=item $port = spawn $node, $initfunc[, @initdata]

Creates a port on the node C<$node> (which can also be a port ID, in which
case it's the node where that port resides).

The port ID of the newly created port is returned immediately, and it is
possible to immediately start sending messages or to monitor the port.

After the port has been created, the init function is called on the remote
node, in the same context as a C<rcv> callback. This function must be a
fully-qualified function name (e.g. C<MyApp::Chat::Server::init>). To
specify a function in the main program, use C<::name>.

If the function doesn't exist, then the node tries to C<require>
the package, then the package above the package and so on (e.g.
C<MyApp::Chat::Server>, C<MyApp::Chat>, C<MyApp>) until the function
exists or it runs out of package names.

The init function is then called with the newly-created port as context
object (C<$SELF>) and the C<@initdata> values as arguments. It I<must>
call one of the C<rcv> functions to set callbacks on C<$SELF>, otherwise
the port might not get created.

A common idiom is to pass a local port, immediately monitor the spawned
port, and in the remote init function, immediately monitor the passed
local port. This two-way monitoring ensures that both ports get cleaned up
when there is a problem.

C<spawn> guarantees that the C<$initfunc> has no visible effects on the
caller before C<spawn> returns (by delaying invocation when spawn is
called for the local node).

Example: spawn a chat server port on C<$othernode>.

   # this node, executed from within a port context:
   my $server = spawn $othernode, "MyApp::Chat::Server::connect", $SELF;
   mon $server;

   # init function on C<$othernode>
   sub connect {
      my ($srcport) = @_;

      mon $srcport;

      rcv $SELF, sub {
         ...
      };
   }

=cut

sub _spawn {
   my $port = shift;
   my $init = shift;

   # rcv will create the actual port
   local $SELF = "$NODE#$port";
   eval {
      &{ load_func $init }
   };
   _self_die if $@;
}

sub spawn(@) {
   my ($nodeid, undef) = split /#/, shift, 2;

   my $id = $RUNIQ . ++$ID;

   $_[0] =~ /::/
      or Carp::croak "spawn init function must be a fully-qualified name, caught";

   snd_to_func $nodeid, "AnyEvent::MP::_spawn" => $id, @_;

   "$nodeid#$id"
}


=item after $timeout, @msg

=item after $timeout, $callback

Either sends the given message, or call the given callback, after the
specified number of seconds.

This is simply a utility function that comes in handy at times - the
AnyEvent::MP author is not convinced of the wisdom of having it, though,
so it may go away in the future.

=cut

sub after($@) {
   my ($timeout, @action) = @_;

   my $t; $t = AE::timer $timeout, 0, sub {
      undef $t;
      ref $action[0]
         ? $action[0]()
         : snd @action;
   };
}

#=item $cb2 = timeout $seconds, $cb[, @args]

=item cal $port, @msg, $callback[, $timeout]

A simple form of RPC - sends a message to the given C<$port> with the
given contents (C<@msg>), but adds a reply port to the message.

The reply port is created temporarily just for the purpose of receiving
the reply, and will be C<kil>ed when no longer needed.

A reply message sent to the port is passed to the C<$callback> as-is.

If an optional time-out (in seconds) is given and it is not C<undef>,
then the callback will be called without any arguments after the time-out
elapsed and the port is C<kil>ed.

If no time-out is given (or it is C<undef>), then the local port will
monitor the remote port instead, so it eventually gets cleaned-up.

Currently this function returns the temporary port, but this "feature"
might go in future versions unless you can make a convincing case that
this is indeed useful for something.

=cut

sub cal(@) {
   my $timeout = ref $_[-1] ? undef : pop;
   my $cb = pop;

   my $port = port {
      undef $timeout;
      kil $SELF;
      &$cb;
   };

   if (defined $timeout) {
      $timeout = AE::timer $timeout, 0, sub {
         undef $timeout;
         kil $port;
         $cb->();
      };
   } else {
      mon $_[0], sub {
         kil $port;
         $cb->();
      };
   }

   push @_, $port;
   &snd;

   $port
}

=back

=head1 DISTRIBUTED DATABASE

AnyEvent::MP comes with a simple distributed database. The database will
be mirrored asynchronously on all global nodes. Other nodes bind to one
of the global nodes for their needs. Every node has a "local database"
which contains all the values that are set locally. All local databases
are merged together to form the global database, which can be queried.

The database structure is that of a two-level hash - the database hash
contains hashes which contain values, similarly to a perl hash of hashes,
i.e.:

  $DATABASE{$family}{$subkey} = $value

The top level hash key is called "family", and the second-level hash key
is called "subkey" or simply "key".

The family must be alphanumeric, i.e. start with a letter and consist
of letters, digits, underscores and colons (C<[A-Za-z][A-Za-z0-9_:]*>,
pretty much like Perl module names.

As the family namespace is global, it is recommended to prefix family names
with the name of the application or module using it.

The subkeys must be non-empty strings, with no further restrictions.

The values should preferably be strings, but other perl scalars should
work as well (such as C<undef>, arrays and hashes).

Every database entry is owned by one node - adding the same family/subkey
combination on multiple nodes will not cause discomfort for AnyEvent::MP,
but the result might be nondeterministic, i.e. the key might have
different values on different nodes.

Different subkeys in the same family can be owned by different nodes
without problems, and in fact, this is the common method to create worker
pools. For example, a worker port for image scaling might do this:

   db_set my_image_scalers => $port;

And clients looking for an image scaler will want to get the
C<my_image_scalers> keys from time to time:

   db_keys my_image_scalers => sub {
      @ports = @{ $_[0] };
   };

Or better yet, they want to monitor the database family, so they always
have a reasonable up-to-date copy:

   db_mon my_image_scalers => sub {
      @ports = keys %{ $_[0] };
   };

In general, you can set or delete single subkeys, but query and monitor
whole families only.

If you feel the need to monitor or query a single subkey, try giving it
it's own family.

=over

=item $guard = db_set $family => $subkey [=> $value]

Sets (or replaces) a key to the database - if C<$value> is omitted,
C<undef> is used instead.

When called in non-void context, C<db_set> returns a guard that
automatically calls C<db_del> when it is destroyed.

=item db_del $family => $subkey...

Deletes one or more subkeys from the database family.

=item $guard = db_reg $family => $port => $value

=item $guard = db_reg $family => $port

=item $guard = db_reg $family

Registers a port in the given family and optionally returns a guard to
remove it.

This function basically does the same as:

   db_set $family => $port => $value

Except that the port is monitored and automatically removed from the
database family when it is kil'ed.

If C<$value> is missing, C<undef> is used. If C<$port> is missing, then
C<$SELF> is used.

This function is most useful to register a port in some port group (which
is just another name for a database family), and have it removed when the
port is gone. This works best when the port is a local port.

=cut

sub db_reg($$;$) {
   my $family = shift;
   my $port = @_ ? shift : $SELF;

   my $clr = sub { db_del $family => $port };
   mon $port, $clr;

   db_set $family => $port => $_[0];

   defined wantarray
      and &Guard::guard ($clr)
}

=item db_family $family => $cb->(\%familyhash)

Queries the named database C<$family> and call the callback with the
family represented as a hash. You can keep and freely modify the hash.

=item db_keys $family => $cb->(\@keys)

Same as C<db_family>, except it only queries the family I<subkeys> and passes
them as array reference to the callback.

=item db_values $family => $cb->(\@values)

Same as C<db_family>, except it only queries the family I<values> and passes them
as array reference to the callback.

=item $guard = db_mon $family => $cb->(\%familyhash, \@added, \@changed, \@deleted)

Creates a monitor on the given database family. Each time a key is
set or is deleted the callback is called with a hash containing the
database family and three lists of added, changed and deleted subkeys,
respectively. If no keys have changed then the array reference might be
C<undef> or even missing.

If not called in void context, a guard object is returned that, when
destroyed, stops the monitor.

The family hash reference and the key arrays belong to AnyEvent::MP and
B<must not be modified or stored> by the callback. When in doubt, make a
copy.

As soon as possible after the monitoring starts, the callback will be
called with the intiial contents of the family, even if it is empty,
i.e. there will always be a timely call to the callback with the current
contents.

It is possible that the callback is called with a change event even though
the subkey is already present and the value has not changed.

The monitoring stops when the guard object is destroyed.

Example: on every change to the family "mygroup", print out all keys.

   my $guard = db_mon mygroup => sub {
      my ($family, $a, $c, $d) = @_;
      print "mygroup members: ", (join " ", keys %$family), "\n";
   };

Exmaple: wait until the family "My::Module::workers" is non-empty.

   my $guard; $guard = db_mon My::Module::workers => sub {
      my ($family, $a, $c, $d) = @_;
      return unless %$family;
      undef $guard;
      print "My::Module::workers now nonempty\n";
   };

Example: print all changes to the family "AnyEvent::Fantasy::Module".

   my $guard = db_mon AnyEvent::Fantasy::Module => sub {
      my ($family, $a, $c, $d) = @_;

      print "+$_=$family->{$_}\n" for @$a;
      print "*$_=$family->{$_}\n" for @$c;
      print "-$_=$family->{$_}\n" for @$d;
   };

=cut

=back

=head1 AnyEvent::MP vs. Distributed Erlang

AnyEvent::MP got lots of its ideas from distributed Erlang (Erlang node
== aemp node, Erlang process == aemp port), so many of the documents and
programming techniques employed by Erlang apply to AnyEvent::MP. Here is a
sample:

   http://www.erlang.se/doc/programming_rules.shtml
   http://erlang.org/doc/getting_started/part_frame.html # chapters 3 and 4
   http://erlang.org/download/erlang-book-part1.pdf      # chapters 5 and 6
   http://erlang.org/download/armstrong_thesis_2003.pdf  # chapters 4 and 5

Despite the similarities, there are also some important differences:

=over 4

=item * Node IDs are arbitrary strings in AEMP.

Erlang relies on special naming and DNS to work everywhere in the same
way. AEMP relies on each node somehow knowing its own address(es) (e.g. by
configuration or DNS), and possibly the addresses of some seed nodes, but
will otherwise discover other nodes (and their IDs) itself.

=item * Erlang has a "remote ports are like local ports" philosophy, AEMP
uses "local ports are like remote ports".

The failure modes for local ports are quite different (runtime errors
only) then for remote ports - when a local port dies, you I<know> it dies,
when a connection to another node dies, you know nothing about the other
port.

Erlang pretends remote ports are as reliable as local ports, even when
they are not.

AEMP encourages a "treat remote ports differently" philosophy, with local
ports being the special case/exception, where transport errors cannot
occur.

=item * Erlang uses processes and a mailbox, AEMP does not queue.

Erlang uses processes that selectively receive messages out of order, and
therefore needs a queue. AEMP is event based, queuing messages would serve
no useful purpose. For the same reason the pattern-matching abilities
of AnyEvent::MP are more limited, as there is little need to be able to
filter messages without dequeuing them.

This is not a philosophical difference, but simply stems from AnyEvent::MP
being event-based, while Erlang is process-based.

You can have a look at L<Coro::MP> for a more Erlang-like process model on
top of AEMP and Coro threads.

=item * Erlang sends are synchronous, AEMP sends are asynchronous.

Sending messages in Erlang is synchronous and blocks the process until
a connection has been established and the message sent (and so does not
need a queue that can overflow). AEMP sends return immediately, connection
establishment is handled in the background.

=item * Erlang suffers from silent message loss, AEMP does not.

Erlang implements few guarantees on messages delivery - messages can get
lost without any of the processes realising it (i.e. you send messages a,
b, and c, and the other side only receives messages a and c).

AEMP guarantees (modulo hardware errors) correct ordering, and the
guarantee that after one message is lost, all following ones sent to the
same port are lost as well, until monitoring raises an error, so there are
no silent "holes" in the message sequence.

If you want your software to be very reliable, you have to cope with
corrupted and even out-of-order messages in both Erlang and AEMP. AEMP
simply tries to work better in common error cases, such as when a network
link goes down.

=item * Erlang can send messages to the wrong port, AEMP does not.

In Erlang it is quite likely that a node that restarts reuses an Erlang
process ID known to other nodes for a completely different process,
causing messages destined for that process to end up in an unrelated
process.

AEMP does not reuse port IDs, so old messages or old port IDs floating
around in the network will not be sent to an unrelated port.

=item * Erlang uses unprotected connections, AEMP uses secure
authentication and can use TLS.

AEMP can use a proven protocol - TLS - to protect connections and
securely authenticate nodes.

=item * The AEMP protocol is optimised for both text-based and binary
communications.

The AEMP protocol, unlike the Erlang protocol, supports both programming
language independent text-only protocols (good for debugging), and binary,
language-specific serialisers (e.g. Storable). By default, unless TLS is
used, the protocol is actually completely text-based.

It has also been carefully designed to be implementable in other languages
with a minimum of work while gracefully degrading functionality to make the
protocol simple.

=item * AEMP has more flexible monitoring options than Erlang.

In Erlang, you can chose to receive I<all> exit signals as messages or
I<none>, there is no in-between, so monitoring single Erlang processes is
difficult to implement.

Monitoring in AEMP is more flexible than in Erlang, as one can choose
between automatic kill, exit message or callback on a per-port basis.

=item * Erlang tries to hide remote/local connections, AEMP does not.

Monitoring in Erlang is not an indicator of process death/crashes, in the
same way as linking is (except linking is unreliable in Erlang).

In AEMP, you don't "look up" registered port names or send to named ports
that might or might not be persistent. Instead, you normally spawn a port
on the remote node. The init function monitors you, and you monitor the
remote port. Since both monitors are local to the node, they are much more
reliable (no need for C<spawn_link>).

This also saves round-trips and avoids sending messages to the wrong port
(hard to do in Erlang).

=back

=head1 RATIONALE

=over 4

=item Why strings for port and node IDs, why not objects?

We considered "objects", but found that the actual number of methods
that can be called are quite low. Since port and node IDs travel over
the network frequently, the serialising/deserialising would add lots of
overhead, as well as having to keep a proxy object everywhere.

Strings can easily be printed, easily serialised etc. and need no special
procedures to be "valid".

And as a result, a port with just a default receiver consists of a single
code reference stored in a global hash - it can't become much cheaper.

=item Why favour JSON, why not a real serialising format such as Storable?

In fact, any AnyEvent::MP node will happily accept Storable as framing
format, but currently there is no way to make a node use Storable by
default (although all nodes will accept it).

The default framing protocol is JSON because a) JSON::XS is many times
faster for small messages and b) most importantly, after years of
experience we found that object serialisation is causing more problems
than it solves: Just like function calls, objects simply do not travel
easily over the network, mostly because they will always be a copy, so you
always have to re-think your design.

Keeping your messages simple, concentrating on data structures rather than
objects, will keep your messages clean, tidy and efficient.

=back

=head1 PORTING FROM AnyEvent::MP VERSION 1.X

AEMP version 2 has a few major incompatible changes compared to version 1:

=over 4

=item AnyEvent::MP::Global no longer has group management functions.

At least not officially - the grp_* functions are still exported and might
work, but they will be removed in some later release.

AnyEvent::MP now comes with a distributed database that is more
powerful. Its database families map closely to port groups, but the API
has changed (the functions are also now exported by AnyEvent::MP). Here is
a rough porting guide:

  grp_reg $group, $port                      # old
  db_reg $group, $port                       # new

  $list = grp_get $group                     # old
  db_keys $group, sub { my $list = shift }   # new

  grp_mon $group, $cb->(\@ports, $add, $del) # old
  db_mon $group, $cb->(\%ports, $add, $change, $del) # new

C<grp_reg> is a no-brainer (just replace by C<db_reg>), but C<grp_get> is
no longer instant, because the local node might not have a copy of the
group. You can either modify your code to allow for a callback, or use
C<db_mon> to keep an updated copy of the group:

  my $local_group_copy;
  db_mon $group => sub { $local_group_copy = $_[0] };

  # now "keys %$local_group_copy" always returns the most up-to-date
  # list of ports in the group.

C<grp_mon> can be replaced by C<db_mon> with minor changes - C<db_mon>
passes a hash as first argument, and an extra C<$chg> argument that can be
ignored:

  db_mon $group => sub {
     my ($ports, $add, $chg, $del) = @_;
     $ports = [keys %$ports];

     # now $ports, $add and $del are the same as
     # were originally passed by grp_mon.
     ...
  };

=item Nodes not longer connect to all other nodes.

In AEMP 1.x, every node automatically loads the L<AnyEvent::MP::Global>
module, which in turn would create connections to all other nodes in the
network (helped by the seed nodes).

In version 2.x, global nodes still connect to all other global nodes, but
other nodes don't - now every node either is a global node itself, or
attaches itself to another global node.

If a node isn't a global node itself, then it attaches itself to one
of its seed nodes. If that seed node isn't a global node yet, it will
automatically be upgraded to a global node.

So in many cases, nothing needs to be changed - one just has to make sure
that all seed nodes are meshed together with the other seed nodes (as with
AEMP 1.x), and other nodes specify them as seed nodes. This is most easily
achieved by specifying the same set of seed nodes for all nodes in the
network.

Not opening a connection to every other node is usually an advantage,
except when you need the lower latency of an already established
connection. To ensure a node establishes a connection to another node,
you can monitor the node port (C<mon $node, ...>), which will attempt to
create the connection (and notify you when the connection fails).

=item Listener-less nodes (nodes without binds) are gone.

And are not coming back, at least not in their old form. If no C<binds>
are specified for a node, AnyEvent::MP assumes a default of C<*:*>.

There are vague plans to implement some form of routing domains, which
might or might not bring back listener-less nodes, but don't count on it.

The fact that most connections are now optional somewhat mitigates this,
as a node can be effectively unreachable from the outside without any
problems, as long as it isn't a global node and only reaches out to other
nodes (as opposed to being contacted from other nodes).

=item $AnyEvent::MP::Kernel::WARN has gone.

AnyEvent has acquired a logging framework (L<AnyEvent::Log>), and AEMP now
uses this, and so should your programs.

Every module now documents what kinds of messages it generates, with
AnyEvent::MP acting as a catch all.

On the positive side, this means that instead of setting
C<PERL_ANYEVENT_MP_WARNLEVEL>, you can get away by setting C<AE_VERBOSE> -
much less to type.

=back

=head1 LOGGING

AnyEvent::MP does not normally log anything by itself, but since it is the
root of the context hierarchy for AnyEvent::MP modules, it will receive
all log messages by submodules.

=head1 SEE ALSO

L<AnyEvent::MP::Intro> - a gentle introduction.

L<AnyEvent::MP::Kernel> - more, lower-level, stuff.

L<AnyEvent::MP::Global> - network maintenance and port groups, to find
your applications.

L<AnyEvent::MP::DataConn> - establish data connections between nodes.

L<AnyEvent::MP::LogCatcher> - simple service to display log messages from
all nodes.

L<AnyEvent>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

