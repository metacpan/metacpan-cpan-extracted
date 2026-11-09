use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k88: a blocking call queued behind a connection the pool
# is still opening, made from inside that opening, is REFUSED -- it does not
# hang, and it does not die of a loop that ran dry.
#
# WHY: a pool opens a connection synchronously, inside acquire, and on the way
# calls code that is not its own and may come back into the pool: the conninfo
# provider -- an AccessBroker's answer, whose client may run the event loop
# while it fetches credentials -- and, once the connection counts, the replay
# of on_connect_do / on_connect_call, which runs the EV loop here until each
# statement is answered. Since core k277 the spawn holds its slot from before
# the first of that code (PoolBase's _spawning), so a call that comes in from
# inside finds no room and is QUEUED although the pool holds fewer connections
# than its size. Made blocking, that call waits for a connection that is handed
# out only after the spawn has returned -- and the spawn is a frame BELOW the
# wait on the call stack. It can never end. The refusal of karr k71 did not see
# it: it looked at the pool's connections only, found none (or one that no
# callback holds), and let the wait run. What happened then depended on what
# else the program had on the loop: with nothing, the wait died with "... the
# EV loop has nothing left that could complete it" -- true, and no hint at the
# cause; with any watcher that keeps the loop alive -- a LISTEN connection, a
# timer of the application -- it hung, with no error, no timeout and no CPU
# (measured against PostgreSQL 18.6 with EV::Pg 0.07 as well,
# t/78-blocking-behind-spawn-live.t).
#
# What this file claims, through the REAL storage and pool over a stand-in
# EV::Pg, each case with and without another watcher that keeps the loop alive:
#   1. pool of one, nothing open yet, the broker's answer itself makes a
#      blocking call on the storage: refused at once with "Blocking wait
#      refused", naming the size of the pool and that the pool is opening one of
#      them in a call this one runs inside; taken out of the queue, never sent.
#      A broker that lets the refusal through fails the call whose connection
#      was being opened with it, and the pool took no slot;
#   2. the same when the broker runs the loop while it fetches, and the blocking
#      call is made by a timer callback that fires in that loop;
#   3. the same for the spawn that replaces a connection retired on release
#      (PoolBase::_spawn_for_next_waiter): made for a caller taken off the
#      queue, it holds the slot the same way;
#   4. the same during the replay of a connect statement: the connection counts
#      by then and no callback holds it -- before it is up, and while the
#      connect statement is in flight;
#   5. pool of two, one connection held by a running then callback, the other
#      being opened: refused -- and the text says that one is being opened, not
#      that callbacks hold every one of them, which is what it said before;
#   6. no refusal where the wait can end, or where nobody waits:
#      a. pool of two, the other connection busy with a statement in flight:
#         the blocking call in the broker's answer returns once that statement
#         has given its connection back;
#      b. pool of two, nothing open: the blocking call in the broker's answer
#         is not queued at all -- it opens a connection of its own and returns;
#      c. pool of two, the other connection busy, the blocking call made by a
#         timer during a connect statement's replay: it returns as in a;
#      d. pool of one, a call in the broker's answer that is NOT waited for
#         (*_async): it stays queued and runs once the spawn has returned;
#   7. the pool's own answer (_pg_held_by_callbacks) in those places.
#
# 1 to 4 fail without the fix: with the other watcher they hang until the
# watchdog below ends the wait, without it they die of the dry loop. 5 fails on
# the text alone. 6 guards against over-refusal: a spawn in flight is no reason
# to refuse while another connection can come back (a, c), a caller that is not
# queued is nobody's to refuse (b), and a queued call nobody blocks on must not
# be failed (d).
#
# THE ONE SUBSTITUTION is EV::Pg, the stand-in of t/56 (see there for what it
# takes from Pg.xs): a read watcher that keeps the loop alive exactly while
# callbacks are queued, results on EV timers in the order sent, a statement
# named slow* or calling pg_sleep answered late. The broker and the owning
# storage are stand-ins of their own, as in t/48 and t/50.
#
# Every wait is bounded by an EV watchdog with keepalive(0): a wait that hangs
# sits in libev's C code, the watchdog fires there, fails every caller queued
# for a connection, and the hang shows up as a failed assertion. The alarm has
# no handler and is never cleared: should the watchdog not get a wait out, the
# signal ends the process.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();
  use Socket ();

  my $ID = 0;

  our $SLOW = 0.1;   # seconds until a slow statement is answered

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      id         => ++$ID,
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      queue      => [],   # sent, callback not returned yet (EV::Pg's cb queue)
      busy       => 0,    # libpq has a command in progress
      wire       => [],   # what was sent, in order: a statement's name or verb
    }, $class;
    socketpair($self->{sock}, $self->{server}, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{up} = 1;
      # start_reading: active from now on. The server never writes here.
      $weak->{rio} = EV::io(fileno $weak->{sock}, EV::READ(), sub { });
      $weak->_idle_ref;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  # update_idle_ref: the read watcher keeps the loop alive while callbacks are
  # queued, and only then.
  sub _idle_ref {
    my ($self) = @_;
    $self->{rio}->keepalive(@{ $self->{queue} } ? 1 : 0) if $self->{rio};
    return;
  }

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { $_[0]{up} ? fileno $_[0]{sock} : -1 }
  sub result_meta   { $_[0]{meta} }

  # A SELECT with bind values is named by the last of them, anything else by
  # its verb.
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};   # REQUIRE_CONN
    die "PQsendQueryParams failed: another command is already in progress\n"
      if $self->{busy};
    my ($verb) = $sql =~ /^(\w+)/;
    my $name = $verb eq 'SELECT' && @$bind ? $bind->[-1] : $verb;
    my $slow = $name =~ /^slow/ || $sql =~ /\bpg_sleep\b/ ? 1 : 0;
    push @{ $self->{wire} }, $name;
    push @{ $self->{queue} }, { verb => $verb, name => $name, slow => $slow, cb => $cb };
    $self->{busy} = 1;
    $self->_idle_ref;
    $self->_arm;
    return;
  }

  sub query { $_[0]->query_params($_[1], [], $_[2]) }

  # cancel_pending, then cleanup_connection: no on_error.
  sub finish {
    my ($self) = @_;
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, 'connection finished'); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    delete $self->{rio};
    $self->{up}   = 0;
    $self->{busy} = 0;
    return;
  }

  sub _arm {
    my ($self) = @_;
    return if $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    my ($next) = grep { !$self->{delivering} || $_ != $self->{delivering} } @{ $self->{queue} };
    my $after  = $next && $next->{slow} ? $SLOW : 0.001;
    $self->{timer} = EV::timer($after, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    my $head = $self->{queue}[0] or return;

    my @result = $head->{verb} eq 'SELECT' ? ([ [ 'row-of', $head->{name} ] ]) : ('');
    $self->{meta} = { cmd_status => $head->{verb} };
    $self->{busy} = 0;
    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    # advance_cb_queue: only now is the callback off the queue.
    shift @{ $self->{queue} } if @{ $self->{queue} } && $self->{queue}[0] == $head;
    $self->_idle_ref;
    $self->_arm;
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use Scalar::Util ();
use DBIO::AccessBroker;
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;

alarm 120;

my $LIMIT = 1;
my $EVF   = 'DBIO::PostgreSQL::EV::Future';

my $REFUSED   = qr/\ABlocking wait refused: /;
my $ADVICE    = qr/\*_async.*->then.*pool_size/s;
my $CALLBACKS = qr/every one of them is held by a callback/;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# An AccessBroker whose answer takes a while: what the test puts in {during}
# happens while it "fetches", once, before it answers.
{
  package K88::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { asked => 0 }, $_[0] }
  sub connect_info_for {
    my ($self) = @_;
    $self->{asked}++;
    if (my $during = delete $self->{during}) { $during->() }
    return { dbname => 'fake' };
  }
}

# The owning sync storage, as far as a spawn asks it: one connect statement for
# every new pool connection (the shape of core's _run_pool_connect_actions).
{
  package K88::Owner;
  sub new { bless { replay => $_[1] }, $_[0] }
  sub _run_pool_connect_actions {
    my ($self, $runner) = @_;
    $runner->($self->{replay}, undef);
    return $self;
  }
  sub _assert_async_context_owner { $_[1] }
}

my @STORAGES;
sub remember {
  my ($storage) = @_;
  push @STORAGES, $storage;
  Scalar::Util::weaken($STORAGES[-1]);
  return $storage;
}

# A real storage with a pool of $size that asks a broker for every connection.
# Attaching asks the broker once.
sub with_broker {
  my ($size) = @_;
  my $broker  = K88::Broker->new;
  my $storage = remember(DBIO::PostgreSQL::EV::Storage->new(undef));
  $storage->connect_info([ $broker, { pool_size => $size } ]);
  return ($storage, $broker);
}

# A real storage with a pool of $size that replays $sql on every new
# connection. The owner is returned too: the storage holds it weakly.
sub with_replay {
  my ($size, $sql) = @_;
  my $storage = remember(DBIO::PostgreSQL::EV::Storage->new(undef));
  $storage->connect_info([ { dbname => 'fake', pool_size => $size }, {} ]);
  my $owner = K88::Owner->new($sql);
  $storage->_owner_storage($owner);
  return ($storage, $owner);
}

sub conns  { @{ $_[0]->pool->{_connections} } }
sub queued { scalar @{ $_[0]->pool->{_waiters} } }
sub wire   { [ @{ $_[0]{wire} } ] }

# What the pool counts: its connections, the idle ones, the spawns in flight
# (core k277) and the callers queued.
sub counts {
  my ($storage) = @_;
  my $pool = $storage->pool;
  return {
    size => $pool->size, available => $pool->available, queued => queued($storage),
    spawning => scalar keys %{ $pool->{_spawning} || {} },
  };
}

# A statement named $name: its Future, and the blocking call. Through the query
# seam -- the blocking storage methods are ->get on what it returns -- because
# the stand-in owner of the replay cases knows nothing of sources.
sub call       { $_[0]->_query_async('SELECT ?::text', [ $_[1] ]) }
sub call_block { call(@_)->get }

# Run $code under the watchdog. Answers ok / error / result, and hung: the wait
# was still blocked after $LIMIT seconds, and the watchdog failed every caller
# queued for a connection to get it out.
sub bounded {
  my ($code) = @_;
  my $hung = 0;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer($LIMIT, 0, sub {
    $hung = 1;
    for my $storage (grep { defined } @STORAGES) {
      my $pool = $storage->{pool} or next;
      $_->fail("watchdog: still blocked after ${LIMIT}s\n")
        for grep { !$_->is_ready } splice @{ $pool->{_waiters} };
    }
  });
  $dog->keepalive(0);
  my @r;
  my $ok = eval { @r = $code->(); 1 };
  return { ok => $ok, error => $ok ? '' : "$@", result => \@r, hung => $hung };
}

# Let every timer the stand-in still has run out.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub nothing_warned {
  my ($label) = @_;
  is_deeply \@warnings, [], "$label: no callback died out of EV::Pg, nothing warned";
  @warnings = ();
}

# The blocking call 'inner' on $storage, made where the test puts it: what the
# pool counted and answered as it was made, how the call ended, and who was
# queued right after.
sub blocking_inner {
  my ($storage, $seen) = @_;
  $seen->{at}   = counts($storage);
  $seen->{held} = $storage->pool->_pg_held_by_callbacks ? 1 : 0;
  my @rows;
  my $ok = eval { @rows = call_block($storage, 'inner'); 1 };
  $seen->{inner}        = { ok => $ok, error => $ok ? '' : "$@", result => \@rows };
  $seen->{queued_after} = queued($storage);
  return;
}

# The blocking call did not hang and did not die of a dry loop: it was refused,
# told the size of the pool, that the pool is opening $opening of its
# connections in a call this one runs inside, and what to do instead. True when
# it was refused; only then is the state of the pool worth looking at.
sub refused_behind_spawn {
  my ($label, $seen, $r, $size, $opening) = @_;
  my $inner = $seen->{inner} || { ok => 0, error => 'the blocking call was never made' };
  ok !$r->{hung}, "$label: the blocking call does not hang"
    or diag "it hung until the watchdog ended the wait after ${LIMIT}s";
  ok !$inner->{ok}, "$label: it dies" or diag 'it returned';
  like $inner->{error}, $REFUSED, "$label: refused";
  like $inner->{error}, qr/\bpool of $size\b/, "$label: naming the size of the pool";
  like $inner->{error}, qr/\bthe pool is opening $opening of them in a call this one runs inside\b/,
    "$label: and what holds the connection it waits for -- a spawn it runs inside";
  unlike $inner->{error}, $CALLBACKS, "$label: not that callbacks hold every connection";
  like $inner->{error}, $ADVICE, "$label: and what to do instead -- the *_async methods with ->then, pool_size";
  my $was = !$r->{hung} && !$inner->{ok} && $inner->{error} =~ $REFUSED;
  if ($was) {
    is $seen->{queued_after}, 0, "$label: it was taken out of the pool's queue as it was refused";
  }
  else {
    note "$label: what the call leaves behind in the pool is not looked at -- it was not refused";
  }
  return $was;
}

# What a refused blocking call must leave behind: nobody queued, no spawn in
# flight, every connection of the pool idle, the call never sent, and the next
# call served. @wire is what each connection was sent, in the order the pool
# opened them.
sub pool_recovered {
  my ($label, $storage, @wire) = @_;
  settle();
  my $size = @wire;
  is_deeply counts($storage), { size => $size, available => $size, queued => 0, spawning => 0 },
    "$label: afterwards the pool has $size connection(s), idle, nobody queued, no spawn in flight";
  is_deeply [ map { wire($_) } conns($storage) ], \@wire, "$label: the refused call was never sent";

  my $next = bounded(sub { call_block($storage, 'next') });
  ok $next->{ok} && !$next->{hung}, "$label: the next call completes"
    or diag $next->{hung} ? 'it hung' : "it failed: $next->{error}";
  is_deeply $next->{result}, [ [ 'row-of', 'next' ] ], "$label: with its own rows";
  settle();
  my @conns = conns($storage);
  is_deeply [ sort map { @{ wire($_) } } @conns ], [ sort 'next', map { @$_ } @wire ],
    "$label: and the refused call does not run later either";
  is $storage->pool->available, scalar @conns, "$label: idle again";
  ok !grep({ /lost a sequence Future/ } @warnings), "$label: no sequence Future was lost"
    or diag @warnings;
}

my %says;   # 7: the pool's own answer, by where it was asked

for my $alive (0, 1) {
  my $with = $alive ? 'another watcher keeps the loop alive' : 'nothing else on the loop';
  # What a LISTEN connection or a timer of the application is to the loop.
  my $other = $alive ? EV::timer(0.2, 0.2, sub { }) : undef;

  # --- 1. the broker's answer makes the blocking call, pool of one ----------------

  {
    my $label = "in the broker's answer, pool of one ($with)";
    my ($storage, $broker) = with_broker(1);
    my %seen;
    $broker->{during} = sub { blocking_inner($storage, \%seen) };
    my $r = bounded(sub { call_block($storage, 'outer') });

    is_deeply $seen{at}, { size => 0, available => 0, queued => 0, spawning => 1 },
      "$label: the call is made with no connection open and the pool's one slot taken by the spawn";
    if (refused_behind_spawn($label, \%seen, $r, 1, 1)) {
      ok $r->{ok}, "$label: the call whose connection was being opened completes -- the broker answered after all"
        or diag $r->{error};
      is_deeply $r->{result}, [ [ 'row-of', 'outer' ] ], "$label: with its own rows";
      pool_recovered($label, $storage, ['outer']);
    }
    $says{"in the broker's answer, pool of one"} = $seen{held};
    nothing_warned($label);
  }

  {
    my $label = "in the broker's answer, which lets the refusal through, pool of one ($with)";
    my ($storage, $broker) = with_broker(1);
    $broker->{during} = sub { call_block($storage, 'inner') };
    my $r = bounded(sub { call_block($storage, 'outer') });

    ok !$r->{hung}, "$label: nothing hangs";
    ok !$r->{ok}, "$label: the call whose connection was being opened fails";
    like $r->{error}, qr/Blocking wait refused: .*\bthe pool is opening 1 of them\b/s,
      "$label: with the refusal its broker died of";
    settle();
    is_deeply counts($storage), { size => 0, available => 0, queued => 0, spawning => 0 },
      "$label: the spawn took no slot, and nobody is queued";
    my $next = bounded(sub { call_block($storage, 'next') });
    ok $next->{ok} && !$next->{hung}, "$label: the next call completes"
      or diag $next->{hung} ? 'it hung' : "it failed: $next->{error}";
    settle();
    is_deeply [ map { wire($_) } conns($storage) ], [ ['next'] ],
      "$label: on a connection of its own; neither refused call was ever sent";
    nothing_warned($label);
  }

  # --- 2. the broker runs the loop, a timer in it makes the blocking call ---------

  {
    my $label = "in a timer while the broker runs the loop, pool of one ($with)";
    my ($storage, $broker) = with_broker(1);
    my %seen;
    $broker->{during} = sub {
      my $fetched = 0;
      my $fetch = EV::timer(0.05, 0, sub { $fetched = 1 });
      my $app   = EV::timer(0.01, 0, sub { blocking_inner($storage, \%seen) });
      EV::run(EV::RUN_ONCE()) until $fetched;
    };
    my $r = bounded(sub { call_block($storage, 'outer') });

    is_deeply $seen{at}, { size => 0, available => 0, queued => 0, spawning => 1 },
      "$label: the call is made with no connection open and the pool's one slot taken by the spawn";
    if (refused_behind_spawn($label, \%seen, $r, 1, 1)) {
      ok $r->{ok}, "$label: the call whose connection was being opened completes" or diag $r->{error};
      is_deeply $r->{result}, [ [ 'row-of', 'outer' ] ], "$label: with its own rows";
      pool_recovered($label, $storage, ['outer']);
    }
    nothing_warned($label);
  }

  # --- 3. the spawn that replaces a retired connection ----------------------------

  {
    my $label = "in the broker's answer for a replacement connection, pool of one ($with)";
    my ($storage, $broker) = with_broker(1);
    call_block($storage, 'warm');
    settle();
    my ($dying) = conns($storage);
    my $first   = call($storage, 'slow-first');
    my $waiting = call($storage, 'waiting');   # queued for the one connection
    is queued($storage), 1, "$label: (a caller is queued behind the statement in flight)";
    # What EV::Pg's on_error tells the pool of a connection it lost: retired
    # when it is released, a fresh one spawned for the oldest queued caller.
    $storage->pool->_mark_connection_dead($dying);
    my %seen;
    $broker->{during} = sub { blocking_inner($storage, \%seen) };
    my $r = bounded(sub { $waiting->get });

    is_deeply $seen{at}, { size => 0, available => 0, queued => 0, spawning => 1 },
      "$label: the call is made with the old connection retired, the queued caller off the queue and its spawn in flight";
    if (refused_behind_spawn($label, \%seen, $r, 1, 1)) {
      ok $r->{ok}, "$label: the caller the replacement was opened for completes" or diag $r->{error};
      is_deeply $r->{result}, [ [ 'row-of', 'waiting' ] ], "$label: with its own rows";
      pool_recovered($label, $storage, ['waiting']);
    }
    nothing_warned($label);
  }

  # --- 4. during the replay of a connect statement --------------------------------

  for my $phase (
    [ 'before the new connection is up', q{SET application_name = 'k88'}, 0,    0 ],
    [ 'with the connect statement in flight', q{SELECT pg_sleep(0.1)},    0.03, 1 ],
  ) {
    my ($when, $replay, $after, $pending) = @$phase;
    my ($verb) = $replay =~ /^(\w+)/;
    my $label  = "in a timer during the connect statement's replay, $when, pool of one ($with)";
    my ($storage, $owner) = with_replay(1, $replay);
    my %seen;
    my $app = EV::timer($after, 0, sub {
      my ($conn) = conns($storage);
      @seen{qw( up pending )} = ($conn->is_connected, $conn->pending_count) if $conn;
      blocking_inner($storage, \%seen);
    });
    my $r = bounded(sub { call_block($storage, 'outer') });

    is_deeply $seen{at}, { size => 1, available => 0, queued => 0, spawning => 0 },
      "$label: the call is made with the new connection counted, not idle, and no longer listed as a spawn";
    is_deeply [ @seen{qw( up pending )} ], [ $pending, $pending ],
      "$label: $when";
    if (refused_behind_spawn($label, \%seen, $r, 1, 1)) {
      ok $r->{ok}, "$label: the call whose connection was being opened completes" or diag $r->{error};
      is_deeply $r->{result}, [ [ 'row-of', 'outer' ] ], "$label: with its own rows";
      pool_recovered($label, $storage, [ $verb, 'outer' ]);
    }
    $says{'during a replay, pool of one'} = $seen{held};
    nothing_warned($label);
  }

  # --- 5. pool of two: one held by a callback, the other being opened -------------

  {
    my $label = "in the broker's answer, inside a then callback, pool of two ($with)";
    my ($storage, $broker) = with_broker(2);
    my %seen;
    my $r = bounded(sub {
      call($storage, 'outer')->then(sub {
        my @outer = @_;
        $broker->{during} = sub { blocking_inner($storage, \%seen) };
        $seen{middle} = [ call_block($storage, 'middle') ];   # opens the second connection
        return $EVF->done(@outer);
      })->get;
    });

    is_deeply $seen{at}, { size => 1, available => 0, queued => 0, spawning => 1 },
      "$label: the call is made with one connection held by the callback and the other slot taken by the spawn";
    if (refused_behind_spawn($label, \%seen, $r, 2, 1)) {
      ok $r->{ok}, "$label: the call whose callback it was completes" or diag $r->{error};
      is_deeply $r->{result}, [ [ 'row-of', 'outer' ] ], "$label: with its own rows";
      is_deeply $seen{middle}, [ [ 'row-of', 'middle' ] ],
        "$label: and so does the one whose connection was being opened";
      pool_recovered($label, $storage, ['outer'], ['middle']);
    }
    $says{'in a then callback and the broker\'s answer, pool of two'} = $seen{held};
    nothing_warned($label);
  }

  # --- 6a. pool of two: the other connection has a statement in flight ------------

  {
    my $label = "in the broker's answer, pool of two, the other connection busy ($with)";
    my ($storage, $broker) = with_broker(2);
    my $slow = call($storage, 'slow');
    my %seen;
    $broker->{during} = sub {
      $seen{before} = $slow->is_ready ? 'ready' : 'pending';
      blocking_inner($storage, \%seen);
      $seen{after} = $slow->is_ready ? 'ready' : 'pending';
    };
    my $r = bounded(sub { call_block($storage, 'outer') });

    is_deeply $seen{at}, { size => 1, available => 0, queued => 0, spawning => 1 },
      "$label: the call is made with one connection checked out and the other slot taken by the spawn";
    is $seen{before}, 'pending', "$label: the checked-out one by a statement in flight";
    ok !$r->{hung}, "$label: nothing hangs";
    ok $seen{inner} && $seen{inner}{ok}, "$label: the blocking call returns"
      or diag $seen{inner} ? "it failed: $seen{inner}{error}" : 'it was never made';
    is_deeply $seen{inner}{result}, [ [ 'row-of', 'inner' ] ], "$label: with its own rows";
    is $seen{after}, 'ready', "$label: after the statement it waited for";
    ok $r->{ok}, "$label: and the call whose connection was being opened completes" or diag $r->{error};
    settle();
    is_deeply [ map { wire($_) } conns($storage) ], [ [qw( slow inner )], ['outer'] ],
      "$label: it ran on the connection that statement gave back";
    is_deeply counts($storage), { size => 2, available => 2, queued => 0, spawning => 0 },
      "$label: both are idle again";
    $says{'in the broker\'s answer, pool of two, the other connection busy'} = $seen{held};
    nothing_warned($label);
  }

  # --- 6b. pool of two, nothing open: there is room, the call is not queued -------

  {
    my $label = "in the broker's answer, pool of two, nothing open ($with)";
    my ($storage, $broker) = with_broker(2);
    my $asked = $broker->{asked};
    my %seen;
    $broker->{during} = sub { blocking_inner($storage, \%seen) };
    my $r = bounded(sub { call_block($storage, 'outer') });

    is_deeply $seen{at}, { size => 0, available => 0, queued => 0, spawning => 1 },
      "$label: the call is made with one slot taken by the spawn and one free";
    ok !$r->{hung}, "$label: nothing hangs";
    ok $seen{inner} && $seen{inner}{ok}, "$label: the blocking call returns"
      or diag $seen{inner} ? "it failed: $seen{inner}{error}" : 'it was never made';
    is_deeply $seen{inner}{result}, [ [ 'row-of', 'inner' ] ], "$label: with its own rows";
    is $broker->{asked} - $asked, 2, "$label: on a connection of its own -- the broker was asked for it too";
    ok $r->{ok}, "$label: and the call whose connection was being opened completes" or diag $r->{error};
    settle();
    is_deeply [ map { wire($_) } conns($storage) ], [ ['inner'], ['outer'] ],
      "$label: each on its own connection";
    is_deeply counts($storage), { size => 2, available => 2, queued => 0, spawning => 0 },
      "$label: both are idle again";
    nothing_warned($label);
  }

  # --- 6c. pool of two: the other connection busy, during a replay -----------------

  {
    my $label = "in a timer during the connect statement's replay, pool of two, the other connection busy ($with)";
    my ($storage, $owner) = with_replay(2, q{SET application_name = 'k88'});
    my $slow = call($storage, 'slow');   # opens the first connection, replay and all
    my %seen;
    my $app = EV::timer(0, 0, sub {
      $seen{before} = $slow->is_ready ? 'ready' : 'pending';
      blocking_inner($storage, \%seen);
      $seen{after} = $slow->is_ready ? 'ready' : 'pending';
    });
    my $r = bounded(sub { call_block($storage, 'outer') });

    is_deeply $seen{at}, { size => 2, available => 0, queued => 0, spawning => 0 },
      "$label: the call is made with both connections counted and neither idle";
    is $seen{before}, 'pending', "$label: the other one checked out by a statement in flight";
    ok !$r->{hung}, "$label: nothing hangs";
    ok $seen{inner} && $seen{inner}{ok}, "$label: the blocking call returns"
      or diag $seen{inner} ? "it failed: $seen{inner}{error}" : 'it was never made';
    is $seen{after}, 'ready', "$label: after the statement it waited for";
    ok $r->{ok}, "$label: and the call whose connection was being opened completes" or diag $r->{error};
    settle();
    is_deeply [ map { wire($_) } conns($storage) ], [ [qw( SET slow inner )], [qw( SET outer )] ],
      "$label: it ran on the connection that statement gave back";
    is_deeply counts($storage), { size => 2, available => 2, queued => 0, spawning => 0 },
      "$label: both are idle again";
    nothing_warned($label);
  }

  # --- 6d. pool of one: a call in the broker's answer that is not waited for ------

  {
    my $label = "in the broker's answer, pool of one, *_async ($with)";
    my ($storage, $broker) = with_broker(1);
    my ($side, %seen);
    $broker->{during} = sub {
      $side = call($storage, 'side');
      %seen = (%{ counts($storage) }, side => $side->is_ready ? 'ready' : 'pending');
    };
    my $r = bounded(sub { call_block($storage, 'outer') });

    is_deeply \%seen, { size => 0, available => 0, queued => 1, spawning => 1, side => 'pending' },
      "$label: the call is queued behind the spawn";
    ok $r->{ok} && !$r->{hung}, "$label: the call whose connection was being opened completes"
      or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
    my $got = bounded(sub { $side->get });
    ok $got->{ok} && !$got->{hung}, "$label: and the queued one runs once the spawn has returned"
      or diag $got->{hung} ? 'it hung' : "it failed: $got->{error}";
    is_deeply $got->{result}, [ [ 'row-of', 'side' ] ], "$label: with its own rows";
    settle();
    is_deeply [ map { wire($_) } conns($storage) ], [ [qw( outer side )] ], "$label: on that connection";
    is_deeply counts($storage), { size => 1, available => 1, queued => 0, spawning => 0 },
      "$label: which is idle again";
    nothing_warned($label);
  }
}

# --- 7. the pool's answer: can no connection come back? -------------------------

is_deeply \%says, {
  "in the broker's answer, pool of one"                              => 1,
  'during a replay, pool of one'                                     => 1,
  'in a then callback and the broker\'s answer, pool of two'         => 1,
  'in the broker\'s answer, pool of two, the other connection busy'  => 0,
}, '_pg_held_by_callbacks: a slot taken by a spawn that is running cannot come back; a statement in flight gives its connection back';

done_testing;
