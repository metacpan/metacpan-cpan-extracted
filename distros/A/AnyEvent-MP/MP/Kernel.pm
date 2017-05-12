=head1 NAME

AnyEvent::MP::Kernel - the actual message passing kernel

=head1 SYNOPSIS

   use AnyEvent::MP::Kernel;

=head1 DESCRIPTION

This module provides most of the basic functionality of AnyEvent::MP,
exposed through higher level interfaces such as L<AnyEvent::MP> and
L<Coro::MP>.

This module is mainly of interest when knowledge about connectivity,
connected nodes etc. is sought.

=head1 GLOBALS AND FUNCTIONS

=over 4

=cut

package AnyEvent::MP::Kernel;

use common::sense;
use POSIX ();
use Carp ();
use MIME::Base64 ();

use AE ();

use AnyEvent::MP::Node;
use AnyEvent::MP::Transport;

use base "Exporter";

our @EXPORT = qw(
   %NODE %PORT %PORT_DATA $UNIQ $RUNIQ $ID
   add_node load_func snd_to_func snd_on eval_on

   NODE $NODE node_of snd kil port_is_local
   configure
   up_nodes mon_nodes node_is_up
);

=item $AnyEvent::MP::Kernel::WARN->($level, $msg)

This value is called with an error or warning message, when e.g. a
connection could not be created, authorisation failed and so on.

It I<must not> block or send messages -queue it and use an idle watcher if
you need to do any of these things.

C<$level> should be C<0> for messages to be logged always, C<1> for
unexpected messages and errors, C<2> for warnings, C<7> for messages about
node connectivity and services, C<8> for debugging messages and C<9> for
tracing messages.

The default simply logs the message to STDERR.

=item @AnyEvent::MP::Kernel::WARN

All code references in this array are called for every log message, from
the default C<$WARN> handler. This is an easy way to tie into the log
messages without disturbing others.

=cut

our $WARNLEVEL = exists $ENV{PERL_ANYEVENT_MP_WARNLEVEL} ? $ENV{PERL_ANYEVENT_MP_WARNLEVEL} : 5;
our @WARN;
our $WARN = sub {
   &$_ for @WARN;

   return if $WARNLEVEL < $_[0];

   my ($level, $msg) = @_;

   $msg =~ s/\n$//;

   printf STDERR "%s <%d> %s\n",
          (POSIX::strftime "%Y-%m-%d %H:%M:%S", localtime time),
          $level,
          $msg;
};

=item $AnyEvent::MP::Kernel::WARNLEVEL [default 5 or $ENV{PERL_ANYEVENT_MP_WARNLEVEL}]

The maximum level at which warning messages will be printed to STDERR by
the default warn handler.

=cut

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

sub nonce($) {
   my $nonce;

   if (open my $fh, "</dev/urandom") {
      sysread $fh, $nonce, $_[0];
   } else {
      # shit...
      $nonce = join "", map +(chr rand 256), 1 .. $_[0]
   }

   $nonce
}

sub alnumbits($) {
   my $data = $_[0];

   if (eval "use Math::GMP 2.05; 1") {
      $data = Math::GMP::get_str_gmp (
                  (Math::GMP::new_from_scalar_with_base (+(unpack "H*", $data), 16)),
                  62
              );
   } else {
      $data = MIME::Base64::encode_base64 $data, "";
      $data =~ s/=//;
      $data =~ s/x/x0/g;
      $data =~ s/\//x1/g;
      $data =~ s/\+/x2/g;
   }

   $data
}

sub gen_uniq {
   alnumbits pack "nna*", $$ & 0xffff, time & 0xffff, nonce 2
}

our $CONFIG; # this node's configuration

our $RUNIQ; # remote uniq value
our $UNIQ;  # per-process/node unique cookie
our $NODE;
our $ID = "a";

our %NODE; # node id to transport mapping, or "undef", for local node
our (%PORT, %PORT_DATA); # local ports

our %RMON; # local ports monitored by remote nodes ($RMON{nodeid}{portid} == cb)
our %LMON; # monitored _local_ ports

our %LISTENER;
our $LISTENER; # our listeners, as arrayref

our $SRCNODE; # holds the sending node during _inject

sub _seed {
   $RUNIQ = alnumbits nonce 96/8;
   $UNIQ  = gen_uniq;
   $NODE  = "anon/$RUNIQ";
}

_seed;

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

sub _delay_run {
   (shift @DELAY_QUEUE or return undef $DELAY_TIMER)->() while 1;
}

sub delay($) {
   push @DELAY_QUEUE, shift;
   $DELAY_TIMER ||= AE::timer 0, 0, \&_delay_run;
}

sub _inject {
   warn "RCV $SRCNODE->{id} -> " . eval { JSON::XS->new->encode (\@_) } . "\n" if TRACE && @_;#d#
   &{ $PORT{+shift} or return };
}

# this function adds a node-ref, so you can send stuff to it
# it is basically the central routing component.
sub add_node {
   my ($node) = @_;

   $NODE{$node} ||= new AnyEvent::MP::Node::Direct $node
}

sub snd(@) {
   my ($nodeid, $portid) = split /#/, shift, 2;

   warn "SND $nodeid <- " . eval { JSON::XS->new->encode (\@_) } . "\n" if TRACE && @_;#d#

   defined $nodeid #d#UGLY
      or Carp::croak "'undef' is not a valid node ID/port ID";

   ($NODE{$nodeid} || add_node $nodeid)
      ->{send} (["$portid", @_]);
}

=item $is_local = port_is_local $port

Returns true iff the port is a local port.

=cut

sub port_is_local($) {
   my ($nodeid, undef) = split /#/, $_[0], 2;

   $NODE{$nodeid} == $NODE{""}
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

   defined $nodeid #d#UGLY
      or Carp::croak "'undef' is not a valid node ID/port ID";

   ($NODE{$nodeid} || add_node $nodeid)->send (["", @_]);
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

sub _nodename {
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

      $t = length $t ? _nodename . ":$t" : _nodename
         if $t =~ /^\d*$/;
      
      my ($host, $port) = AnyEvent::Socket::parse_hostport $t, 0
         or Carp::croak "$t: unparsable transport descriptor";

      $port = "0" if $port eq "*";

      if ($host eq "*") {
         $cv->begin;
         # use fork_call, as Net::Interface is big, and we need it rarely.
         require AnyEvent::Util;
         AnyEvent::Util::fork_call (
            sub {
               my @addr;

               require Net::Interface;

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
               @addr
            }, sub {
               for my $ip (@_) {
                  push @res, [
                     $pri += 1e-5,
                     AnyEvent::Socket::format_hostport AnyEvent::Socket::format_address $ip, $port
                  ];
               }
               $cv->end;
            }
         );
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

sub configure(@) {
   unshift @_, "profile" if @_ & 1;
   my (%kv) = @_;

   delete $NODE{$NODE}; # we do not support doing stuff before configure
   _seed;

   my $profile = delete $kv{profile};

   $profile = _nodename
      unless defined $profile;

   $CONFIG = AnyEvent::MP::Config::find_profile $profile, %kv;

   my $node = exists $CONFIG->{nodeid} ? $CONFIG->{nodeid} : $profile;

   $node or Carp::croak "$node: illegal node ID (see AnyEvent::MP manpage for syntax)\n";

   $NODE = $node
      unless $node eq "anon/";

   $NODE{$NODE} = $NODE{""};
   $NODE{$NODE}{id} = $NODE;

   my $seeds = $CONFIG->{seeds};
   my $binds = $CONFIG->{binds};

   $binds ||= ["*"];

   $WARN->(8, "node $NODE starting up.");

   $LISTENER = [];
   %LISTENER = ();

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
         $LISTENER{$bind} = $listener;
         push @$LISTENER, $bind;
      }
   }

   $WARN->(8, "node listens on [@$LISTENER].");

   # the global service is mandatory currently
   require AnyEvent::MP::Global;

   # connect to all seednodes
   AnyEvent::MP::Global::set_seeds (map $_->recv, map _resolve $_, @$seeds);

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
}

#############################################################################
# node monitoring and info

=item node_is_known $nodeid

Returns true iff the given node is currently known to the system. The only
time a node is known but not up currently is when a conenction request is
pending.

=cut

sub node_is_known($) {
   exists $NODE{$_[0]}
}

=item node_is_up $nodeid

Returns true if the given node is "up", that is, the kernel thinks it has
a working connection to it.

If the node is known but not currently connected, returns C<0>. If the
node is not known, returns C<undef>.

=cut

sub node_is_up($) {
   ($NODE{$_[0]} or return)->{transport}
      ? 1 : 0
}

=item known_nodes

Returns the node IDs of all nodes currently known to this node, including
itself and nodes not currently connected.

=cut

sub known_nodes() {
   map $_->{id}, values %NODE
}

=item up_nodes

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

Note that monitoring a node is usually better done by monitoring it's node
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

   defined wantarray && AnyEvent::Util::guard { delete $MON_NODES{$cb+0} }
}

sub _inject_nodeevent($$;@) {
   my ($node, $up, @reason) = @_;

   for my $cb (values %MON_NODES) {
      eval { $cb->($node->{id}, $up, @reason); 1 }
         or $WARN->(1, $@);
   }

   $WARN->(7, "$node->{id} is " . ($up ? "up" : "down") . " (@reason)");
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
      or $WARN->(2, "unmonitored local port $port died with reason: @_");

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

our %node_req = (
   # internal services

   # monitoring
   mon0 => sub { # stop monitoring a port for another node
      my $portid = shift;
      _unmonitor undef, $portid, delete $SRCNODE->{rmon}{$portid};
   },
   mon1 => sub { # start monitoring a port for another node
      my $portid = shift;
      Scalar::Util::weaken (my $node = $SRCNODE);
      _monitor undef, $portid, $node->{rmon}{$portid} = sub {
         delete $node->{rmon}{$portid};
         $node->send (["", kil0 => $portid, @_])
            if $node && $node->{transport};
      };
   },
   # another node has killed a monitored port
   kil0 => sub {
      my $cbs = delete $SRCNODE->{lmon}{+shift}
         or return;

      $_->(@_) for @$cbs;
   },

   # "public" services - not actually public

   # another node wants to kill a local port
   kil => \&_kill,

   # relay message to another node / generic echo
   snd => \&snd,
   snd_multiple => sub {
      snd @$_ for @_
   },

   # informational
   info => sub {
      snd @_, $NODE;
   },
   known_nodes => sub {
      snd @_, known_nodes;
   },
   up_nodes => sub {
      snd @_, up_nodes;
   },

   # random utilities
   eval => sub {
      my @res = do { package main; eval shift };
      snd @_, "$@", @res if @_;
   },
   time => sub {
      snd @_, AE::time;
   },
   devnull => sub {
      #
   },
   "" => sub {
      # empty messages are keepalives or similar devnull-applications
   },
);

$NODE{""} = $NODE{$NODE} = new AnyEvent::MP::Node::Self $NODE;
$PORT{""} = sub {
   my $tag = shift;
   eval { &{ $node_req{$tag} ||= load_func $tag } };
   $WARN->(2, "error processing node message: $@") if $@;
};

=back

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

