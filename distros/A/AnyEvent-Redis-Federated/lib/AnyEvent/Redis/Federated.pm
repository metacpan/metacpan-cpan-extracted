package AnyEvent::Redis::Federated;

# An AnyEvent-based Redis client which implements timeouts, connection
# retries, multi-machine pool configuration (including consistent
# hashing), and other magic bits. 

use strict;
use warnings;
use AnyEvent::Redis;
use AnyEvent;
use Set::ConsistentHash;   # for hash ring logic
use Digest::MD5 qw(md5);   # for hashing keys
use Scalar::Util qw(weaken);
use List::Util qw(shuffle);

our $VERSION = "0.08";

# keep a global object cache that will contain weak references to
# objects keyed on their tag.  this allows for sharing of objects
# within a given process by modules that are otherwise unaware of
# each other provided they use the same tag.
our %object_cache;

# These are all for failure handling (server down or unresponsive).
# If a connection to a given server fails, we'll retry up to
# MAX_HOST_RETRIES and then only retry once in a while.  That
# interval is dictated by BASE_RETRY_INTERVAL.  If that retry fails,
# we'll multiply that by RETRY_INTERVAL_MULT up to but not exceeding
# MAX_RETRY_INTERVAL.
#
# If we ever get a successful retry, we'll erase any memory of the
# failure and pretend things are just fine.

use constant MAX_HOST_RETRIES      =>   3; # how many in a row before we pass
use constant BASE_RETRY_INTERVAL   =>   2; # in seconds
use constant RETRY_INTERVAL_MULT   =>   2; # multiply this much each retry fail
use constant MAX_RETRY_INTERVAL    => 600; # no more than this long
use constant DEFAULT_WEIGHT        =>  10; # for consistent hashing
use constant COMMAND_TIMEOUT       =>   1; # used in poll()
use constant QUERY_ALL             =>   0; # don't query all addresses by default

my %defaults = (
	command_timeout     => COMMAND_TIMEOUT,
	max_host_retries    => MAX_HOST_RETRIES,
	base_retry_interval => BASE_RETRY_INTERVAL,
	retry_interval_mult => RETRY_INTERVAL_MULT,
	max_retry_interval  => MAX_RETRY_INTERVAL,
	query_all           => QUERY_ALL,
	quiet               => $ENV{QUIET},
);

sub new {
	my $class = shift;
	my $self = { @_ };

	# tag short circuit
	if ($self->{tag}) {
		if ($object_cache{$self->{tag}}) {
			return $object_cache{$self->{tag}};
		}
	}

	# basic init
	while (my ($k, $v) = each %defaults) {
		next if exists $self->{$k};
		$self->{$k} = $v;
	}

	# condvar for finishing up stuff (used in poll())
	$self->{cv} = undef;

	# setup server_status tracking
	$self->{server_status} = { };

	# request state
	$self->{request_serial} = 0;
	$self->{request_state} = { };

	# we must have configuration
	if (not $self->{config}) {
		die("No configuration provided. Can't instantiate Redis client");
	}

	# populate node list
	$self->{nodes} = [keys %{$self->{config}->{nodes}}];

	if ($self->{debug}) {
		print "node list: ", join ', ', @{$self->{nodes}};
		print "\n";
	}

	# setup the addresses array
	foreach my $node (keys %{$self->{config}->{nodes}}) {
		if ($self->{config}->{nodes}->{$node}->{addresses}) {
			# shuffle the existing addresses array
			@{$self->{config}->{nodes}->{$node}->{addresses}} = shuffle(@{$self->{config}->{nodes}->{$node}->{addresses}});
			# and set the first to be our targeted server
			$self->{config}->{nodes}->{$node}->{address} = ${$self->{config}->{nodes}->{$node}->{addresses}}[-1];
		}
	}

	# setup the consistent hash
	my $set = Set::ConsistentHash->new;
	my @targets = map { $_, DEFAULT_WEIGHT } @{$self->{nodes}};
	$set->set_targets(@targets);
	$set->set_hash_func(\&_hash);
	$self->{set} = $set;
	$self->{buckets} = $self->{set}->buckets;

	$self->{idle_timeout} = 0 if not exists $self->{idle_timeout};

	print "config done.\n" if $self->{debug};
	bless $self, $class;

	# cache it for later use
	if ($self->{tag}) {
		$object_cache{$self->{tag}} = $self;
		weaken($object_cache{$self->{tag}});
	}

	return $self;
}

sub removeNode {
	my ($self, $node) = @_;
	$self->{set}->modify_targets($node => 0);
	$self->{buckets} = $self->{set}->buckets;
}

sub addNode {
	my ($self, $name, $ref) = @_;
	$self->{config}->{nodes}->{$name} = $ref;
	$self->{set}->modify_targets($name => DEFAULT_WEIGHT);
	$self->{buckets} = $self->{set}->buckets;
}

sub DESTROY {
}

sub _hash {
	return unpack("N", md5(shift));
}

sub commandTimeout {
	my ($self, $time) = @_;
	if (defined $time) {
		$self->{command_timeout} = $time;
	}
	return $self->{command_timeout};
}

sub queryAll {
	my ($self, $val) = @_;
	if (defined $val) {
		$self->{query_all} = $val;
	}
	return $self->{query_all};
}

sub nodeToHost {
	my ($self, $node) = @_;
	return $self->{config}->{nodes}->{$node}->{address};
}

sub keyToNode {
	my ($self, $key) = @_;
	my $node = $self->{buckets}->[_hash($key) % 1024];
	return $node;
}

sub isServerDown {
	my ($self, $server) = @_;
	return 1 if $self->{server_status}{"$server:down"};
 	return 0;
}

sub isServerUp {
	my ($self, $server) = @_;
	return 0 if $self->{server_status}{"$server:down"};
	return 1;
}

sub nextServer {
	my ($self, $server, $node) = @_;
	return $server unless $self->{config}->{nodes}->{$node}->{addresses};
	$self->{config}->{nodes}->{$node}->{address} = shift(@{$self->{config}->{nodes}->{$node}->{addresses}});
	push @{$self->{config}->{nodes}->{$node}->{addresses}}, $self->{config}->{nodes}->{$node}->{address};
	warn "redis server for $node changed from $server to $self->{config}->{nodes}->{$node}->{address} selected\n" if $self->{debug};
	return $self->{config}->{nodes}->{$node}->{address};
}

## return only on-line/up servers?

sub allServers {
	my ($self, $node) = @_;
	my $hosts = [ grep { $self->isServerUp($_) } @{$self->{config}->{nodes}->{$node}->{addresses}} ];
	return $hosts;
}

sub markServerUp {
	my ($self, $server) = @_;
	if ($self->{server_status}{"$server:down"}) {
		my $down_since = localtime($self->{server_status}{"$server:down_since"});
		delete $self->{server_status}{"$server:down"};
		delete $self->{server_status}{"$server:retries"};
		delete $self->{server_status}{"$server:down_since"};
		delete $self->{server_status}{"$server:retry_pending"};
		delete $self->{server_status}{"$server:retry_interval"};
 		warn "redis server $server back up (down since $down_since)\n" if $self->{debug};
	}
	return 1;
}

sub markServerDown {
	my ($self, $server, $delay) = @_;
	$delay ||= $self->{base_retry_interval};
	warn "redis server $server seems down\n" if $self->{debug};

	# first time?
	if (not $self->{server_status}{"$server:down"}) {
		warn "server $server down, first time\n" if $self->{debug};
		$self->{server_status}{"$server:down"} = 1;
		$self->{server_status}{"$server:retries"}++;
		$self->{server_status}{"$server:down_since"} = time();
		$self->{server_status}{"$server:retry_interval"} ||= $self->{base_retry_interval};
	}

	if ($self->{server_status}{"$server:retry_pending"}) {
		warn "retry already pending for $server, skipping\n" if $self->{debug};
		return 1;
	}

	# ok, schedule the timer to re-check. this should NOT be a
	# recurring timer, otherwise we end up with a bunch of pending
	# retries since the "interval" is likely shorter than TCP timeout.
	# eventually this will error out, in which case we'll try it again
	# by calling markServerDown() after clearying retry_pending, or
	# it'll work and we're good to go.
	my $t;
	my $r;
	$t = AnyEvent->timer(
		after => $delay,
		cb => sub {
			warn "timer callback triggered for $server" if $self->{debug};
			my ($host, $port) = split /:/, $server;
			print "attempting reconnect to $server\n" if $self->{debug};
			$r = AnyEvent::Redis->new(
				host => $host,
				port => $port,
				on_error => sub {
					warn @_ unless $self->{quiet};
					$self->{server_status}{"$server:retry_pending"} = 0;
					$self->markServerDown($server); # schedule another try
				}
			);

			$r->ping(sub{
				my $val = shift; # should be 'PONG'
				if ($val ne 'PONG') {
					warn "retry ping got $val instead of PONG" if $self->{debug};
				}
				$self->{conn}->{$server} = $r;
				$self->{server_status}{"$server:retry_pending"} = 0;
				$self->markServerUp($server);
				undef $t; # we need to keep a ref to the timer here so it runs at all
			 });
		}
	);
	warn "scheduled health check of $server in $delay secs\n" if $self->{debug};
	$self->{server_status}{"$server:retry_pending"} = 1;
	return 1;
}

our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;
	my $call = lc $AUTOLOAD;
	$call =~ s/.*:://;
	print "method [$call] autoloaded\n" if $self->{debug};

	my $key = $_[0];
	my $hk  = $key;
	my $cb  = sub { };

	if (ref $_[-1] eq 'CODE') {
		$cb = pop @_;
	}

	# key group?
	if (ref($_[0]) eq 'ARRAY') {
		$hk  = $_[0]->[0];
		$key = $_[0]->[1];
		$_[0] = $key;
	}

	my $node = $self->keyToNode($hk);
	my $query_all = $self->{query_all};

	if ($call =~ s/_all$//) {
		$query_all = 1;
	}

	## The normal single-server case...
	if (not $query_all) {
		my $server = $self->nodeToHost($node);
		print "server [$server] of node [$node] for key [$key] hashkey [$hk]\n" if $self->{debug};

		if ($self->isServerDown($server)) {
			# try another if we can
			if ($self->{config}->{nodes}->{$node}->{addresses}) {
				print "server [$server] seems down\n" if $self->{debug};
				$server = $self->nextServer($server, $node);
				print "trying next server in line [$server] for node [$node]\n" if $self->{debug};
			}
			# bail otherwise
			else {
				print "server $server down.  abandoning call.\n" if $self->{debug};
				$cb->(undef);
				return $self;
			}
		}

		return $self->scheduleCall($server, $call, [@_], $cb);
	}

	## Need to fire this one at all up servers in the node group...
	else {
		my $servers = $self->allServers($node);
		for my $server (@$servers) {
			$self->scheduleCall($server, $call, [@_], $cb);
		}
		return $self;
	}
}

sub poll {
	my ($self) = @_;
	#return if $self->{pending_requests} < 1;
	return if not defined $self->{cv};
	my $rid = $self->{request_serial};
	my $timeout = $self->{command_timeout};

	my $w;
	if ($timeout) {
		$w = AnyEvent->signal(signal => "ALRM", cb => sub {
			warn "AnyEvent::Redis::Federated::poll alarm timeout! ($rid)\n" if $self->{debug};

			# check the state of requests, marking remaining as cancelled
			while (my ($rid, $state) = each %{$self->{request_state}}) {
				if ($self->{request_state}->{$rid}) {
					print "found pending request to cancel: $rid\n" if $self->{debug};
					$self->{request_state}->{$rid} = 0;
					$self->{cv}->end;
					undef $w;
				}
			}
		});
		print "scheduling alarm timer in poll() for $timeout\n" if $self->{debug};
		alarm($timeout);
	}

	$self->{cv}->recv;
	$self->{cv} = undef;
	alarm(0);
	undef $w;
}

sub scheduleCall {
	my ($self, $server, $call, $args, $cb) = @_;

	# have a non-idle connection already?
	my $r;
	if ($self->{conn}->{$server}) {
		if ($self->{idle_timeout}) {
			if ($self->{last_used}->{$server} > time - $self->{idle_timeout}) {
				$r = $self->{conn}->{$server};
			}
		}
		else {
			$r = $self->{conn}->{$server};
		}
	}

	# otherwise create a new connection
	if (not defined $r) {
		my ($host, $port) = split /:/, $server;
		print "attempting new connection to $server\n" if $self->{debug};
		$r = AnyEvent::Redis->new(
			host => $host,
			port => $port,
			on_error => sub {
				warn @_ unless $self->{quiet};
				$self->markServerDown($server);
				$self->{cv}->end;
			}
		);

		$self->{conn}->{$server} = $r;
	}

	if (not defined $self->{cv}) {
		$self->{cv} = AnyEvent->condvar;
	}

	$self->{cv}->begin;
	$self->{request_serial}++;
	my $rid = $self->{request_serial};
	$self->{request_state}->{$rid} = 1; # open request; 0 is cancelled
	print "scheduling request $rid: $_[0]\n" if $self->{debug};

	if ($call eq 'multi' or $call eq 'exec') {
		@$args = (); # these don't really take args
	}

	$r->$call(@$args, sub {
		if (not $self->{request_state}->{$rid}) {
			print "call found request $rid cancelled\n" if $self->{debug};
			delete $self->{request_state}->{$rid};
			$self->markServerDown($server);
			$cb->(undef);
			return;
		}
		$self->{cv}->end;
		$self->markServerUp($server);
		$self->{last_used}->{$server} = time;
		print "callback completed for request $rid\n" if $self->{debug};
		delete $self->{request_state}->{$rid};
		$cb->(shift);
	});
	return $self;
}

=head1 NAME

AnyEvent::Redis::Federated - Full-featured Async Perl Redis client

=head1 SYNOPSIS

  use AnyEvent::Redis::Federated;

  my $r = AnyEvent::Redis::Federated->new(%opts);

  # batch up requests and explicity wait for completion
  $redis->set("foo$_", "bar$_") for 1..20;
  $redis->poll;

  # send a request with a callback
  $redis->get("foo1", sub {
    my $val = shift;
    print "cb got: $val\n"; # should print "cb got: 1"
  });
  $redis->poll;

=head1 DESCRIPTION

This is a wrapper around AnyEvent::Redis which adds timeouts,
connection retries, multi-machine cluster configuration (including
consistent hashing), node groups, and other magic bits.

=head2 HASHING AND SCALING

Keys are run through a consistent hashing algorithm to map them to
"nodes" which ultimately map to instances defined by back-end
host:port entries.  For example, the C<redis_1> node may map to the
host and port C<redis1.example.com:63791>, but that'll all be
transparent to the user.

However, there are features in Redis that are handy if you know a
given set of keys lives on a single insance (a wildcard fetch like
C<KEYS gmail*>, for example).  To facilitate that, you can specify a
"key group" that will be hashed insead of hashing the key.

For example:

  key group: gmail
  key      : foo@gmail.com

  key group: gmail
  key      : bar@gmail.com

Put another way, the key group defaults to the key for the named
operation, but if specified, is used instead as the input to the
consistent hashing function.

Using the same key group means that multiple keys end up on the same
Redis instance.  To do so, simply change any key in a call to an
arrayref where item 0 is the key group and item 1 is the key.

  $r->set(['gmail', 'foo@gmail.com'], 'spammer', $cb);
  $r->set(['gmail', 'bar@gmail.com'], 'spammer', $cb);

Anytime a key is an arrayref, AnyEvent::Redis::Federated will assume
you're using a key group.

=head2 PERSISTENT CONNECTIONS

By default, AnyEvent::Redis::Federated will use a new connection for
each command.  You can enable persistent connections by passing a
C<persistent> agrument (with a true value) in C<new()>.  You will
likely also want to set a C<idle_timeout> value as well.  The
idle_timeout defaults to 0 (which means no timeout).  But if set to a
posistive value, that's the number of seconds that a connection is
allowed to remain idle before it is re-established.  A number up to 60
seconds is probably reasonable.

=head2 SHARED CONNECTIONS

Because creating AnyEvent::Redis::Federated objects isn't cheap (due
mainly to initializing the consistent hashing ring), there is a
mechanism for sharing a connection object among modules without prior
knowledge of each other.  If you specify a C<tag> in the C<new()>
constructor and another module in the same process tries to create an
object with the same tag, it will get a reference to the one you
created.

For example, in your code:

  my $redis = AnyEvent::Redis::Federated->new(tag => 'rate-limiter');

Then in another module:

  my $r = AnyEvent::Redis::Federated->new(tag => 'rate-limiter');

Both C<$redis> and C<$r> will be references to the same object.

Since the first module to create an object with a given tag gets to
define the various retry parameters (as described in the next section),
it's worth thinking about whether or not you really want this behavior.
In many cases, you may--but not in all cases.

Tag names are used as a hash key internally and compared using Perl's
normal stringification mechanism, so you could use a full-blown object
as your tag if you wanted to do such a thing.

=head2 CONNECTION RETRIES

If a connection to a server goes down, AnyEvent::Redis::Federated will
notice and retry on subsequent calls.  If the server remains down after
a configured number of tries, it will go into back-off mode, retrying
occasionally and increasing the time between retries until the server
is back on-line or the retry interval time has reached the maximum
configured vaue.

The module has some hopefully sane defaults built in, but you can
override any or all of them in your code when creating an
AnyEvent::Redis::Federated object.  The following keys contol this
behvaior (defaults listed in parens for each):

   * max_host_retries (3) is the number of times a server will be
     re-tried before starting the back-off logic

   * base_retry_interval (10) is the number of seconds between retries
     when entering back-off mode

   * retry_interval_mult (2) is the number we'll multiply
     base_retry_interval by on each subsequent failure in back-off
     mode

   * max_retry_interval (600) is the number of seconds that the retry
     interval will not exceed

When a server first goes down, this module will C<warn()> a message
that says "redis server $server seems down\n" where $server is the
$host:$port pair that represents the connection to the server.  If
this is the first time that server has been seen down, it will
additionally C<warn()> "redis server $server down, first time\n".

If a server remainds down on subsequent retries beyond
max_host_retries, the module will C<warn()> "redis server $server
still down, backing off" to let you know that the back-off logic is
about to kick in.  Each time the retry_interval is increased, it will
C<warn()> "redis server $server retry_interval now $retry_interval".

If a down server does come back up, the module will C<warn()> "redis
server $server back up (down since $down_since)\n" where $down_since
is human readable timestamp.  It will also clear all internal state
about the down server.

=head2 TIMEOUTS

This module provides support for command timeouts.

The command timeout controls how long we're willing to wait for a
response to a given request made to a Redis server.  Redis usually
responds VERY quickly to most requests.  But if there's a temporary
network problem or something tying up the server, you may wish to fail
quickly and move on.

NOTE: these timeouts are implemented using C<alarm()>, so be careful
of also using C<alarm()> calls in your own code that could interfere.

=head2 MULTI-KEY OPERATIONS

Some operations can operate on many keys and might cross server
boundries.  They are currently supported provided that you remember to
specify a hash key to ensure the all live on the same node.  Example
operations are:

  * mget
  * sinter
  * sinterstore
  * sdiff
  * sdiffstore
  * zunionstore

Previous versions of this module listed these as unsupported commands,
but that's rather limiting.  So they're supported now, provided you
know what you're doing.

=head2 METHODS

AnyEvent::Redis::Federated inherits all of the normal Redis methods.
However, you can supply a callback or AnyEvent condvar as the final
argument and it'll do the right thing:

  $redis->get("foo", sub { print shift,"\n"; });

You can also use call chaining:

  $redis->set("foo", 1)->set("bar", 2)->get("foo", sub {
    my $val = shift;
    print "foo: $val\n";
  });

=head2 CONFIGURATION

AnyEvent::Redis::Federated requires a configuration hash be passed
to it at instantiation time. The constructor will die() unless a
unless a 'config' option is passed to it. The configuration structure
looks like:

  my $config = {
    nodes => {
      redis_1 => { address => 'db1:63790' },
      redis_2 => { address => 'db1:63791' },
      redis_3 => { address => 'db2:63790' },
      redis_4 => { address => 'db2:63791' },
    },
  };

The "nodes" and "master_of" hashes are described below.

=head3 NODES

The "nodes" configuation maps an arbitrary node name to a host:port
pair.  (The hostname can be replaced with an IP address.)

Node names (redis_N in the example above) are VERY important since
they are the keys used to build the consistent hashing ring. It's
generally the wrong idea to change a node name. Since node names are
mapped to a host:port pair, we can move a node from one host to
another without rehashing a bunch of keys.

There is unlikely to be a need to remove a node.

Adding nodes to a cluster is currently not well-supported, but is an
area of active development.

=head2 EVENT LOOP

Since this module wraps AnyEvent::Redis, there are two main ways you
can integrate it into your code.  First, if you're using AnyEvent, it
should "just work."  However, if you're not otherwise using AnyEvent,
you can still take advantage of batching up requests and waiting for
them in parallel by calling the C<poll()> method as illustrated in the
synopsis.

Calling C<poll()> asks the module to issue any pending requests and
wait for all of them to return before returning control back to your
code.

=head2 EXPORT

None.

=head2 SEE ALSO

The normal AnyEvent::Redis perl client C<perldoc AnyEvent::Redis>.

The Redis API documentation:

  http://redis.io/commands

Jeremy Zawodny's blog describing craigslist's use of redis sharding:

  http://blog.zawodny.com/2011/02/26/redis-sharding-at-craigslist/

That posting described an implementation which was based on the
regular (non-async) Redis client from CPAN.  This code is a port of
that to AnyEvent.

=head2 BUGS

Please report bugs as issues on github:

  https://github.com/craigslist/perl-AnyEvent-Redis-Federated/issues

=head1 AUTHOR

Jeremy Zawodny, E<lt>jzawodn@craigslist.orgE<gt>

Joshua Thayer, E<lt>joshua@craigslist.orgE<gt>

Tyle Phelps, E<lt>tyler@craigslist.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by craigslist.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

__END__
