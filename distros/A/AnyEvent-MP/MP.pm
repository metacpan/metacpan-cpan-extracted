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
   mon $localport, $cb->(@msg)      # callback is invoked on death
   mon $localport, $otherport       # kill otherport on abnormal death
   mon $localport, $otherport, @msg # send message on death

   # temporarily execute code in port context
   peval $port, sub { die "kill the port!" };

   # execute callbacks in $SELF port context
   my $timer = AE::timer 1, 0, psub {
      die "kill the port, delayed";
   };

=head1 CURRENT STATUS

   bin/aemp                - stable.
   AnyEvent::MP            - stable API, should work.
   AnyEvent::MP::Intro     - explains most concepts.
   AnyEvent::MP::Kernel    - mostly stable API.
   AnyEvent::MP::Global    - stable API.

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

=item port ID - C<nodeid#portname>

A port ID is the concatenation of a node ID, a hash-mark (C<#>) as
separator, and a port name (a printable string of unspecified format).

=item node

A node is a single process containing at least one port - the node port,
which enables nodes to manage each other remotely, and to create new
ports.

Nodes are either public (have one or more listening ports) or private
(no listening ports). Private nodes cannot talk to other private nodes
currently.

=item node ID - C<[A-Za-z0-9_\-.:]*>

A node ID is a string that uniquely identifies the node within a
network. Depending on the configuration used, node IDs can look like a
hostname, a hostname and a port, or a random string. AnyEvent::MP itself
doesn't interpret node IDs in any way.

=item binds - C<ip:port>

Nodes can only talk to each other by creating some kind of connection to
each other. To do this, nodes should listen on one or more local transport
endpoints - binds. Currently, only standard C<ip:port> specifications can
be used, which specify TCP ports to listen on.

=item seed nodes

When a node starts, it knows nothing about the network. To teach the node
about the network it first has to contact some other node within the
network. This node is called a seed.

Apart from the fact that other nodes know them as seed nodes and they have
to have fixed listening addresses, seed nodes are perfectly normal nodes -
any node can function as a seed node for others.

In addition to discovering the network, seed nodes are also used to
maintain the network and to connect nodes that otherwise would have
trouble connecting. They form the backbone of an AnyEvent::MP network.

Seed nodes are expected to be long-running, and at least one seed node
should always be available. They should also be relatively responsive - a
seed node that blocks for long periods will slow down everybody else.

=item seeds - C<host:port>

Seeds are transport endpoint(s) (usually a hostname/IP address and a
TCP port) of nodes that should be used as seed nodes.

The nodes listening on those endpoints are expected to be long-running,
and at least one of those should always be available. When nodes run out
of connections (e.g. due to a network error), they try to re-establish
connections to some seednodes again to join the network.

=back

=head1 VARIABLES/FUNCTIONS

=over 4

=cut

package AnyEvent::MP;

use AnyEvent::MP::Kernel;

use common::sense;

use Carp ();

use AE ();

use base "Exporter";

our $VERSION = '1.30';

our @EXPORT = qw(
   NODE $NODE *SELF node_of after
   configure
   snd rcv mon mon_guard kil psub peval spawn cal
   port
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

=item configure $profile, key => value...

=item configure key => value...

Before a node can talk to other nodes on the network (i.e. enter
"distributed mode") it has to configure itself - the minimum a node needs
to know is its own name, and optionally it should know the addresses of
some other nodes in the network to discover other nodes.

The key/value pairs are basically the same ones as documented for the
F<aemp> command line utility (sans the set/del prefix).

This function configures a node - it must be called exactly once (or
never) before calling other AnyEvent::MP functions.

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
this process. If not, then the profile name will be used as node ID. The
special node ID of C<anon/> will be replaced by a random node ID.

=item step 2, bind listener sockets

The next step is to look up the binds in the profile, followed by binding
aemp protocol listeners on all binds specified (it is possible and valid
to have no binds, meaning that the node cannot be contacted form the
outside. This means the node cannot talk to other nodes that also have no
binds, but it can still talk to all "normal" nodes).

If the profile does not specify a binds list, then a default of C<*> is
used, meaning the node will bind on a dynamically-assigned port on every
local IP address it finds.

=item step 3, connect to seed nodes

As the last step, the seeds list from the profile is passed to the
L<AnyEvent::MP::Global> module, which will then use it to keep
connectivity with at least one node at any point in time.

=back

Example: become a distributed node using the local node name as profile.
This should be the most common form of invocation for "daemon"-type nodes.

   configure

Example: become an anonymous node. This form is often used for commandline
clients.

   configure nodeid => "anon/";

Example: configure a node using a profile called seed, which si suitable
for a seed node as it binds on all local addresses on a fixed port (4040,
customary for aemp).

   # use the aemp commandline utility
   # aemp profile seed nodeid anon/ binds '*:4040'

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

sub _kilme {
   die "received message on port without callback";
}

sub port(;&) {
   my $id = "$UNIQ." . $ID++;
   my $port = "$NODE#$id";

   rcv $port, shift || \&_kilme;

   $port
}

=item rcv $local_port, $callback->(@msg)

Replaces the default callback on the specified port. There is no way to
remove the default callback: use C<sub { }> to disable it, or better
C<kil> the port when it is no longer needed.

The global C<$SELF> (exported by this module) contains C<$port> while
executing the callback. Runtime errors during callback execution will
result in the port being C<kil>ed.

The default callback received all messages not matched by a more specific
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

   $NODE{$nodeid} == $NODE{""}
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

Evaluates the given C<$codref> within the contetx of C<$port>, that is,
when the code throews an exception the C<$port> will be killed.

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

=item $guard = mon $port, $cb->(@reason)    # call $cb when $port dies

=item $guard = mon $port, $rcvport          # kill $rcvport when $port dies

=item $guard = mon $port                    # kill $SELF when $port dies

=item $guard = mon $port, $rcvport, @msg    # send a message when $port dies

Monitor the given port and do something when the port is killed or
messages to it were lost, and optionally return a guard that can be used
to stop monitoring again.

In the first form (callback), the callback is simply called with any
number of C<@reason> elements (no @reason means that the port was deleted
"normally"). Note also that I<< the callback B<must> never die >>, so use
C<eval> if unsure.

In the second form (another port given), the other port (C<$rcvport>)
will be C<kil>'ed with C<@reason>, if a @reason was specified, i.e. on
"normal" kils nothing happens, while under all other conditions, the other
port is killed with the same reason.

The third form (kill self) is the same as the second form, except that
C<$rvport> defaults to C<$SELF>.

In the last form (message), a message of the form C<@msg, @reason> will be
C<snd>.

Monitoring-actions are one-shot: once messages are lost (and a monitoring
alert was raised), they are removed and will not trigger again.

As a rule of thumb, monitoring requests should always monitor a port from
a local port (or callback). The reason is that kill messages might get
lost, just like any other message. Another less obvious reason is that
even monitoring requests can get lost (for example, when the connection
to the other node goes down permanently). When monitoring a port locally
these problems do not exist.

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
      and ($cb += 0, AnyEvent::Util::guard { $node->unmonitor ($port, $cb) })
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

=cut

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

   my $id = "$RUNIQ." . $ID++;

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

Erlang uses processes that selectively receive messages, and therefore
needs a queue. AEMP is event based, queuing messages would serve no
useful purpose. For the same reason the pattern-matching abilities of
AnyEvent::MP are more limited, as there is little need to be able to
filter messages without dequeuing them.

(But see L<Coro::MP> for a more Erlang-like process model on top of AEMP).

=item * Erlang sends are synchronous, AEMP sends are asynchronous.

Sending messages in Erlang is synchronous and blocks the process (and
so does not need a queue that can overflow). AEMP sends are immediate,
connection establishment is handled in the background.

=item * Erlang suffers from silent message loss, AEMP does not.

Erlang implements few guarantees on messages delivery - messages can get
lost without any of the processes realising it (i.e. you send messages a,
b, and c, and the other side only receives messages a and c).

AEMP guarantees (modulo hardware errors) correct ordering, and the
guarantee that after one message is lost, all following ones sent to the
same port are lost as well, until monitoring raises an error, so there are
no silent "holes" in the message sequence.

=item * Erlang can send messages to the wrong port, AEMP does not.

In Erlang it is quite likely that a node that restarts reuses a process ID
known to other nodes for a completely different process, causing messages
destined for that process to end up in an unrelated process.

AEMP never reuses port IDs, so old messages or old port IDs floating
around in the network will not be sent to an unrelated port.

=item * Erlang uses unprotected connections, AEMP uses secure
authentication and can use TLS.

AEMP can use a proven protocol - TLS - to protect connections and
securely authenticate nodes.

=item * The AEMP protocol is optimised for both text-based and binary
communications.

The AEMP protocol, unlike the Erlang protocol, supports both programming
language independent text-only protocols (good for debugging) and binary,
language-specific serialisers (e.g. Storable). By default, unless TLS is
used, the protocol is actually completely text-based.

It has also been carefully designed to be implementable in other languages
with a minimum of work while gracefully degrading functionality to make the
protocol simple.

=item * AEMP has more flexible monitoring options than Erlang.

In Erlang, you can chose to receive I<all> exit signals as messages
or I<none>, there is no in-between, so monitoring single processes is
difficult to implement. Monitoring in AEMP is more flexible than in
Erlang, as one can choose between automatic kill, exit message or callback
on a per-process basis.

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

