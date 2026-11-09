use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k70 / k71: a blocking call made inside a callback that
# holds the pool's last connection is REFUSED -- it does not hang.
#
# WHY: every blocking storage method is ->get on its *_async sibling, and
# DBIO::PostgreSQL::EV::Future's get runs the EV loop until the Future is
# ready. A then callback on a pooled statement runs while that statement's
# connection is still checked out (settle, then release: karr k44 / k51), and
# a txn_do coderef runs inside the BEGIN's callback on the connection the
# transaction keeps until COMMIT or ROLLBACK. A blocking call on the STORAGE
# there needs another connection. With a pool of one there is none and none
# can be spawned: the call is queued for the connection its own caller holds,
# which comes back only after that caller has returned. Nothing is sent and
# nothing is in flight, so no result will ever arrive -- but EV::Pg's read
# watcher on the held connection is still active and still counted, so the
# loop does not run dry either: until karr k71 the wait hung, with no error,
# no timeout and no CPU. dbio-mysql-ev refuses its twin (its karr k53,
# t/33-blocking-on-exhausted-pool-mock.t there).
#
# What this file claims, through the REAL storage and pool over a stand-in
# EV::Pg:
#   1. the case is the one meant: in a then callback on a pooled statement,
#      and in a txn_do coderef, the pool of one has nothing idle and is at its
#      size; the call whose callback it is keeps its own result;
#   2. no refusal where the wait can end -- where a connection can still come
#      back while the callbacks on the stack run:
#      a. top level, pool of one: a blocking call queued behind a statement in
#         flight returns once that statement has given the connection back;
#      b. pool of two: a blocking call in a then callback gets the other
#         connection and returns;
#      c. pool of one: a call in a then callback that is NOT waited for
#         (*_async) is queued and runs once the callback has returned;
#      d. pool of two, in a then callback, the other connection busy with a
#         statement in flight: the blocking call waits for it and returns;
#      e. pool of two, in a then callback, the other connection still
#         connecting, for a call nobody waits for: the blocking call waits for
#         that call and returns;
#      f. pool of two, in a then callback, the other connection held by a
#         transaction none of whose callbacks runs and that has nothing in
#         flight -- its coderef returned a Future a timer settles: the
#         blocking call returns once the transaction has committed;
#      g. pool of one, in a then callback, with a call nobody waits for queued
#         for the held connection: a blocking wait for something else -- a
#         Future a timer settles -- returns, and the queued call stays queued;
#   3. the blocking call of 1 is refused: it dies at once with "Blocking wait
#      refused", naming the size of the pool and what to do instead (the
#      *_async methods chained with ->then, the transaction context, a larger
#      pool_size). It is taken out of the pool's queue right there and is
#      never sent, then or later; the pool is idle and serves the next call;
#      no sequence Future is lost and nothing warns. Also:
#      a. a blocking txn_do on the storage in a txn_do coderef, pool of one:
#         the inner coderef never runs, the inner transaction never begins;
#      b. pool of two, a blocking call in a then callback that runs inside the
#         blocking wait of another then callback: the call chain holds both
#         connections, and the call is refused, naming a pool of 2.
#
#   5. the same holds for the other ways a wait is given up while the Future
#      hangs off a queued caller (karr k85, k86; sections 5a-5e below):
#      a. the k44 refusal -- a txn_do coderef sends a $ctx statement, then a
#         blocking select / insert on the storage: refused with the k44 text,
#         taken out of the queue, never sent, whether the coderef dies or goes
#         on to COMMIT, with a chain that catches the failure, with a callback
#         on the failed waiter that dies, and in a convergent beside a statement
#         on the wire; a call that was never queued (pool of two) still
#         completes;
#      b. the loop running dry -- a transaction holds the one connection, its
#         coderef returned a Future nobody has settled: the blocking call dies
#         with "nothing left", nobody stays queued, and once the transaction
#         ends the pool is idle, serves the next call, and nothing warns.
#
# 3 fails without the refusal: every case hangs until the watchdog below ends
# the wait after a second. It also fails for a refusal that only dies and
# leaves its caller queued: the next release hands the connection to that
# caller, and the refused call runs after all -- or, its chain dropped, the
# connection is lost and the pool of one is wedged. 2 guards against
# over-refusal: it fails if an exhausted pool is taken for a hopeless one (a,
# d, e, f), if a blocking call in a callback is refused as such (b), if a
# queued call nobody blocks on is failed (c, g), or if every blocking wait is
# refused while the callbacks on the stack hold the pool (g). 4 asks the pool
# directly.
#
# THE ONE SUBSTITUTION is EV::Pg itself, as in t/41 and t/55: a fake the real
# pool builds through its real, fork-safe constructor. What it takes from
# EV::Pg (Pg.xs, 0.02 and 0.07 alike -- read there, not measured here; the
# first, which the file stands on, is held against PostgreSQL in
# t/62-blocking-on-empty-pool-live.t, karr k73):
#   - the read watcher on the connection's socket is started when the connect
#     completes and stays active for as long as the handle is connected. It
#     keeps EV::run alive exactly while callbacks are queued
#     (update_idle_ref: pending_count > 0), and a callback is taken off the
#     queue only after it has returned (advance_cb_queue, after
#     deliver_result) -- so the watcher still counts while the callback of the
#     LAST answer runs. That is what made the wait of 3 a hang instead of a
#     loop that runs dry, and the whole file stands on it. Here it is a real
#     EV::io on a socketpair the "server" never writes to;
#   - results arrive on EV timers, in the order sent -- that of a statement
#     named slow* late -- and are delivered after the command's last result
#     was read: libpq is idle again inside the callback, which is called under
#     an eval that only warns;
#   - outside pipeline mode a dispatch while a statement is in flight croaks
#     "another command is already in progress" before it queues anything.
#
# Every wait is bounded by an EV watchdog with keepalive(0). A wait that hangs
# sits in libev's C code; the watchdog fires there, fails every caller queued
# for a connection, and the hang shows up as a failed assertion. The alarm has
# no handler: should the watchdog itself not get the wait out, the signal ends
# the process, so a hang never outlives the file.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();
  use Socket ();

  my $ID = 0;

  our $SLOW = 0.1;   # seconds until a statement named slow* is answered

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

  # A SELECT is named by its last bind value, anything else by its verb.
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};   # REQUIRE_CONN
    die "PQsendQueryParams failed: another command is already in progress\n"
      if $self->{busy};
    my ($verb) = $sql =~ /^(\w+)/;
    my $name = $verb eq 'SELECT' && @$bind ? $bind->[-1] : $verb;
    push @{ $self->{wire} }, $name;
    push @{ $self->{queue} }, { verb => $verb, name => $name, cb => $cb };
    $self->{busy} = 1;
    $self->_idle_ref;
    $self->_arm;
    return;
  }

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
    my $after  = $next && $next->{name} =~ /^slow/ ? $SLOW : 0.001;
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
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;

alarm 60;

my $LIMIT = 1;
my $EVF   = 'DBIO::PostgreSQL::EV::Future';

# 3: the refusal, and what it tells the caller to do instead.
my $REFUSED = qr/\ABlocking wait refused: /;
my $ADVICE  = qr/\*_async.*->then.*\$ctx->select_async.*pool_size/s;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my @STORAGES;
sub build_storage {
  my ($size, %options) = @_;
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => $size, %options }, {} ]);
  push @STORAGES, $storage;
  Scalar::Util::weaken($STORAGES[-1]);
  return $storage;
}

sub conns  { @{ $_[0]->pool->{_connections} } }
sub queued { scalar @{ $_[0]->pool->{_waiters} } }
sub wire   { [ @{ $_[0]{wire} } ] }

my @COLS = qw( tag name );
sub select_named       { $_[0]->select_async('thing', \@COLS, { name => $_[1] }) }
sub select_named_block { $_[0]->select('thing', \@COLS, { name => $_[1] }) }

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

# Let every timer the fake still has run out.
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

# What a refused blocking call must leave behind: nobody queued, every
# connection of the pool idle, the call never sent, and the next call served.
# @wire is what each connection was sent, in the order the pool opened them.
sub pool_recovered {
  my ($label, $storage, @wire) = @_;
  settle();
  my @conns = conns($storage);
  my $size  = @wire;
  is queued($storage), 0, "$label: nobody is left queued for a connection";
  is $storage->pool->size, $size, "$label: the pool still has its $size connection(s)";
  is $storage->pool->available, $size, "$label: idle";
  is_deeply [ map { wire($_) } @conns ], \@wire, "$label: the refused call was never sent";

  my $next = bounded(sub { select_named_block($storage, 'next') });
  ok $next->{ok} && !$next->{hung}, "$label: the next call completes"
    or diag $next->{hung} ? 'it hung' : "it failed: $next->{error}";
  is_deeply $next->{result}, [ [ 'row-of', 'next' ] ], "$label: with its own rows";
  settle();
  is_deeply [ sort map { @{ wire($_) } } @conns ], [ sort 'next', map { @$_ } @wire ],
    "$label: and the refused call does not run later either";
  is $storage->pool->available, $size, "$label: idle again";
  ok !grep({ /lost a sequence Future/ } @warnings), "$label: no sequence Future was lost"
    or diag @warnings;
}

# 3: the blocking call $r stands for did not hang -- it died, refused, told the
# size of the pool and what to do instead. True when it was refused; only then
# is there a state of the pool worth looking at -- after a hang it is the
# watchdog that emptied the queue.
sub refused {
  my ($label, $r, $size) = @_;
  ok !$r->{hung}, "$label: the blocking call does not hang"
    or diag "it hung until the watchdog ended the wait after ${LIMIT}s";
  ok !$r->{ok}, "$label: it dies" or diag 'it returned';
  like $r->{error}, $REFUSED, "$label: refused";
  like $r->{error}, qr/\bpool of $size\b/, "$label: naming the size of the pool";
  like $r->{error}, $ADVICE,
    "$label: and what to do instead -- the *_async methods with ->then, the transaction context, pool_size";
  my $was = !$r->{hung} && !$r->{ok} && $r->{error} =~ $REFUSED;
  note "$label: what the call leaves behind in the pool is not looked at -- it was not refused"
    unless $was;
  return $was;
}

# --- 1 / 3. in a then callback on a pooled statement, pool of one ---------------

{
  my $label   = 'then callback, pool of one';
  my $storage = build_storage(1);
  my %seen;
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      my @outer = @_;
      @seen{qw( size available )} = ($storage->pool->size, $storage->pool->available);
      my $ok = eval { select_named_block($storage, 'inner'); 1 };
      $seen{inner}    = { ok => $ok, error => $ok ? '' : "$@" };
      $seen{queued}   = queued($storage);
      $seen{returned} = 1;
      return $EVF->done(@outer);
    })->get;
  });

  is_deeply [ @seen{qw( size available )} ], [ 1, 0 ],
    "$label: the callback runs with the pool's one connection checked out -- nothing idle, nothing to spawn";
  ok $seen{returned}, "$label: the blocking call came back to the callback, one way or the other";
  ok $r->{ok}, "$label: the call whose callback it was completes" or diag $r->{error};
  is_deeply $r->{result}, [ [ 'row-of', 'outer' ] ], "$label: with its own rows";

  my $inner = { %{ $seen{inner} || { ok => 0, error => 'the callback never ran' } }, hung => $r->{hung} };
  if (refused($label, $inner, 1)) {
    is $seen{queued}, 0, "$label: it was taken out of the pool's queue as it was refused";
    pool_recovered($label, $storage, ['outer']);
  }
  nothing_warned($label);
}

# --- 1 / 3. in a txn_do coderef, pool of one -------------------------------------

{
  my $label   = 'txn_do coderef, pool of one';
  my $storage = build_storage(1);
  my %seen;
  my $r = bounded(sub {
    $storage->txn_do(sub {
      @seen{qw( size available )} = ($storage->pool->size, $storage->pool->available);
      my $ok  = eval { select_named_block($storage, 'inner'); 1 };   # on the storage, not on the context
      my $err = $@;
      $seen{queued} = queued($storage);
      die $err unless $ok;
      $seen{returned} = 1;
      return 'committed';
    });
  });

  is_deeply [ @seen{qw( size available )} ], [ 1, 0 ],
    "$label: the coderef runs with the pool's one connection pinned -- nothing idle, nothing to spawn";

  ok !$seen{returned}, "$label: the blocking call did not return to the coderef";
  if (refused($label, $r, 1)) {   # txn_do dies with what its coderef died with
    is $seen{queued}, 0, "$label: it was taken out of the pool's queue as it was refused";
    pool_recovered($label, $storage, [qw( BEGIN ROLLBACK )]);
  }
  nothing_warned($label);
}

# --- 3a. a blocking txn_do in a txn_do coderef, pool of one ----------------------

{
  my $label   = 'txn_do in a txn_do coderef, pool of one';
  my $storage = build_storage(1);
  my ($inner_ran, $returned) = (0, 0);
  my $r = bounded(sub {
    $storage->txn_do(sub {
      $storage->txn_do(sub { $inner_ran++; return 'inner' });
      $returned = 1;
      return 'committed';
    });
  });

  ok !$returned, "$label: the inner txn_do did not return to the coderef";
  is $inner_ran, 0, "$label: and its own coderef never ran";
  refused($label, $r, 1)   # one BEGIN: the inner transaction never began
    and pool_recovered($label, $storage, [qw( BEGIN ROLLBACK )]);
  nothing_warned($label);
}

# --- 3b. pool of two: the call chain holds both connections ----------------------

{
  my $label   = 'then callback inside the blocking wait of a then callback, pool of two';
  my $storage = build_storage(2);
  my %seen;
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      my @outer = @_;
      # Blocks inside the callback of the first connection, for the second: fine.
      $seen{middle} = [ select_named($storage, 'middle')->then(sub {
        my @middle = @_;
        @seen{qw( size available )} = ($storage->pool->size, $storage->pool->available);
        my $ok = eval { select_named_block($storage, 'inner'); 1 };
        $seen{inner}  = { ok => $ok, error => $ok ? '' : "$@" };
        $seen{queued} = queued($storage);
        return $EVF->done(@middle);
      })->get ];
      return $EVF->done(@outer);
    })->get;
  });

  is_deeply [ @seen{qw( size available )} ], [ 2, 0 ],
    "$label: the inner callback runs with both connections checked out -- nothing idle, nothing to spawn";
  ok $r->{ok}, "$label: the outer call completes" or diag $r->{error};
  is_deeply $r->{result}, [ [ 'row-of', 'outer' ] ], "$label: with its own rows";
  is_deeply $seen{middle}, [ [ 'row-of', 'middle' ] ], "$label: and so does the one it blocked on";

  my $inner = { %{ $seen{inner} || { ok => 0, error => 'the callback never ran' } }, hung => $r->{hung} };
  if (refused($label, $inner, 2)) {
    is $seen{queued}, 0, "$label: it was taken out of the pool's queue as it was refused";
    pool_recovered($label, $storage, ['outer'], ['middle']);
  }
  nothing_warned($label);
}

# --- 2a. top level: queued behind a statement in flight --------------------------

{
  my $label   = 'top level, behind a statement in flight';
  my $storage = build_storage(1);
  my $first   = select_named($storage, 'first');
  is queued($storage), 0, "$label: (the first call has the connection)";
  my $r = bounded(sub { select_named_block($storage, 'second') });
  ok $r->{ok} && !$r->{hung}, "$label: a blocking call queued for the busy connection returns"
    or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
  is_deeply $r->{result}, [ [ 'row-of', 'second' ] ], "$label: with its own rows";
  ok $first->is_done, "$label: after the statement it waited for";
  settle();
  is_deeply wire((conns($storage))[0]), [qw( first second )], "$label: on the connection that statement gave back";
  is $storage->pool->available, 1, "$label: which is idle again";
  nothing_warned($label);
}

# --- 2b. pool of two: the callback's call gets the other connection --------------

{
  my $label   = 'then callback, pool of two';
  my $storage = build_storage(2);
  my %seen;
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      @seen{qw( size available )} = ($storage->pool->size, $storage->pool->available);
      my @rows = select_named_block($storage, 'inner');
      return $EVF->done(@rows);
    })->get;
  });
  is_deeply [ @seen{qw( size available )} ], [ 1, 0 ],
    "$label: the callback runs with its connection checked out, and the pool has room for one more";
  ok $r->{ok} && !$r->{hung}, "$label: a blocking call in the callback returns"
    or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
  is_deeply $r->{result}, [ [ 'row-of', 'inner' ] ], "$label: with its own rows";
  settle();
  my ($held, $other) = conns($storage);
  is_deeply [ map { wire($_) } grep { defined } $held, $other ], [ ['outer'], ['inner'] ],
    "$label: it ran on the other connection, not on the one being delivered";
  is $storage->pool->available, 2, "$label: both are idle again";
  nothing_warned($label);
}

# --- 2c. pool of one: a call in the callback that is not waited for --------------

{
  my $label   = 'then callback, pool of one, *_async';
  my $storage = build_storage(1);
  my $inner;
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      $inner = select_named($storage, 'inner');
      return $EVF->done(queued($storage), $inner->is_ready ? 'ready' : 'pending');
    })->get;
  });
  ok $r->{ok} && !$r->{hung}, "$label: the outer call completes" or diag $r->{error};
  is_deeply $r->{result}, [ 1, 'pending' ],
    "$label: the callback's own call was queued for the connection the callback holds";
  my $got = bounded(sub { $inner->get });
  ok $got->{ok} && !$got->{hung}, "$label: and runs once the callback has returned"
    or diag $got->{hung} ? 'it hung' : "it failed: $got->{error}";
  is_deeply $got->{result}, [ [ 'row-of', 'inner' ] ], "$label: with its own rows";
  settle();
  is_deeply wire((conns($storage))[0]), [qw( outer inner )], "$label: on that same connection";
  is $storage->pool->available, 1, "$label: which is idle again";
  nothing_warned($label);
}

# --- 2d. pool of two: the other connection has a statement in flight -------------

{
  my $label   = 'then callback, pool of two, the other connection busy';
  my $storage = build_storage(2);
  my $slow    = select_named($storage, 'slow');
  my %seen;
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      @seen{qw( size available before )}
        = ($storage->pool->size, $storage->pool->available, $slow->is_ready ? 'ready' : 'pending');
      my @rows = select_named_block($storage, 'inner');
      $seen{after} = $slow->is_ready ? 'ready' : 'pending';
      return $EVF->done(@rows);
    })->get;
  });
  is_deeply [ @seen{qw( size available before )} ], [ 2, 0, 'pending' ],
    "$label: the callback runs with both connections checked out, the other one by a statement in flight";
  ok $r->{ok} && !$r->{hung}, "$label: a blocking call in the callback returns"
    or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
  is_deeply $r->{result}, [ [ 'row-of', 'inner' ] ], "$label: with its own rows";
  is $seen{after}, 'ready', "$label: after the statement it waited for";
  settle();
  is_deeply [ map { wire($_) } conns($storage) ], [ [qw( slow inner )], ['outer'] ],
    "$label: on the connection that statement gave back";
  is $storage->pool->available, 2, "$label: both are idle again";
  nothing_warned($label);
}

# --- 2e. pool of two: the other connection is still connecting -------------------

{
  my $label   = 'then callback, pool of two, the other connection still connecting';
  my $storage = build_storage(2);
  my ($side, %seen);
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      $side = select_named($storage, 'side');   # opens the second connection; nobody waits for it
      @seen{qw( size available up )} = ($storage->pool->size, $storage->pool->available,
        join ' ', map { $_->is_connected } conns($storage));
      my @rows = select_named_block($storage, 'inner');
      $seen{after} = $side->is_ready ? 'ready' : 'pending';
      return $EVF->done(@rows);
    })->get;
  });
  is_deeply [ @seen{qw( size available up )} ], [ 2, 0, '1 0' ],
    "$label: the callback runs with the pool at its size, its second connection not up yet";
  ok $r->{ok} && !$r->{hung}, "$label: a blocking call in the callback returns"
    or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
  is_deeply $r->{result}, [ [ 'row-of', 'inner' ] ], "$label: with its own rows";
  is $seen{after}, 'ready', "$label: after the call that connection was opened for";
  settle();
  is_deeply [ map { wire($_) } conns($storage) ], [ ['outer'], [qw( side inner )] ],
    "$label: on the connection that call gave back";
  is $storage->pool->available, 2, "$label: both are idle again";
  nothing_warned($label);
}

# --- 2f. pool of two: the other connection held by a transaction that waits ------

{
  my $label   = 'then callback, pool of two, the other connection held by a waiting transaction';
  my $storage = build_storage(2);
  my $gate    = $EVF->new;
  my $txn     = $storage->txn_do_async(sub { return $gate });
  settle();   # BEGIN is answered and the coderef has returned
  my ($held) = conns($storage);
  my ($open, %seen);
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      @seen{qw( size available pending before )} = ($storage->pool->size, $storage->pool->available,
        $held->pending_count, $txn->is_ready ? 'ready' : 'pending');
      $open = EV::timer($EV::Pg::SLOW, 0, sub { $gate->done('committed') });
      my @rows = select_named_block($storage, 'inner');
      $seen{after} = $txn->is_ready ? 'ready' : 'pending';
      return $EVF->done(@rows);
    })->get;
  });
  is_deeply [ @seen{qw( size available pending before )} ], [ 2, 0, 0, 'pending' ],
    "$label: the callback runs with both connections checked out, the other one by a transaction with nothing in flight";
  ok $r->{ok} && !$r->{hung}, "$label: a blocking call in the callback returns"
    or diag $r->{hung} ? 'it hung' : "it failed: $r->{error}";
  is_deeply $r->{result}, [ [ 'row-of', 'inner' ] ], "$label: with its own rows";
  is $seen{after}, 'ready', "$label: after the transaction";
  settle();
  is_deeply [ map { wire($_) } conns($storage) ], [ [qw( BEGIN COMMIT inner )], ['outer'] ],
    "$label: on the connection the transaction gave back";
  is $storage->pool->available, 2, "$label: both are idle again";
  nothing_warned($label);
}

# --- 2g. pool of one: a blocking wait for something else, beside a queued call ---

{
  my $label   = 'then callback, pool of one, a wait for something else';
  my $storage = build_storage(1);
  my ($inner, %seen);
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      $inner = select_named($storage, 'inner');   # queued for the held connection; nobody waits for it
      $seen{queued} = queued($storage);
      my $tick = $EVF->new;
      my $t    = EV::timer(0.02, 0, sub { $tick->done('tick') });
      $seen{tick}  = eval { $tick->get } // "died: $@";
      $seen{after} = queued($storage) . ' queued, ' . ($inner->is_ready ? 'ready' : 'pending');
      return $EVF->done('outer');
    })->get;
  });
  ok $r->{ok} && !$r->{hung}, "$label: the outer call completes" or diag $r->{error};
  is_deeply \%seen, { queued => 1, tick => 'tick', after => '1 queued, pending' },
    "$label: a blocking wait for a timer returns, and the queued call it does not depend on is left queued";
  my $got = bounded(sub { $inner->get });
  ok $got->{ok} && !$got->{hung}, "$label: which runs once the callback has returned"
    or diag $got->{hung} ? 'it hung' : "it failed: $got->{error}";
  is_deeply $got->{result}, [ [ 'row-of', 'inner' ] ], "$label: with its own rows";
  settle();
  is $storage->pool->available, 1, "$label: and the connection is idle again";
  nothing_warned($label);
}

# --- 4. the pool's answer: is every connection held by a running callback? -------

{
  my $label   = 'the pool, asked';
  my $storage = build_storage(1);
  my $pool    = $storage->pool;
  my %held;
  my $first = select_named($storage, 'first');
  $held{'top level, a statement in flight'} = $pool->_pg_held_by_callbacks;
  my $r = bounded(sub {
    $first->then(sub {
      $held{'in a then on a pooled statement'} = $pool->_pg_held_by_callbacks;
      return $EVF->done;
    })->get;
    settle();
    $held{'top level, idle'} = $pool->_pg_held_by_callbacks;
    $storage->txn_do_async(sub {
      my ($ctx) = @_;
      $held{'in a txn_do coderef'} = $pool->_pg_held_by_callbacks;
      my $sent = $ctx->select_async('thing', \@COLS, { name => 'in-txn' });
      $held{'in a txn_do coderef with a statement in flight'} = $pool->_pg_held_by_callbacks;
      return $sent;
    })->get;
  });
  ok $r->{ok} && !$r->{hung}, "$label: (the calls it was asked in complete)" or diag $r->{error};
  is_deeply \%held, {
    'top level, a statement in flight'               => 0,
    'top level, idle'                                => 0,
    'in a then on a pooled statement'                => 1,
    'in a txn_do coderef'                            => 1,
    'in a txn_do coderef with a statement in flight' => 0,
  }, "$label: held only where a callback of each connection runs and nothing else is pending on it";
  nothing_warned($label);
}

# --- 5. a wait given up on takes the queued caller out of the queue ----------------
#
# Every way out of await that gives the wait up while the Future hangs off a
# caller queued for a connection takes that caller out of the queue and fails
# it (karr k85, k86). Case 3 above is the way out of the k71 refusal; these are
# the other two: the k44 refusal (a result is due on the connection whose
# callback runs) and the loop running dry.

# 5a. the k44 refusal. A txn_do coderef sends a $ctx statement, then makes a
# blocking call on the STORAGE: k44 speaks first (a result is due on the
# pinned connection), and the call is queued for that very connection.
for my $call (
  [ 'select', sub { select_named_block($_[0], 'inner') },                       'inner'  ],
  [ 'insert', sub { $_[0]->insert('thing', { name => 'inner-insert' }) },       'INSERT' ],
) {
  my ($kind, $block, $sent) = @$call;

  # The coderef dies with the refusal: the transaction rolls back.
  {
    my $label   = "k85, txn_do coderef with a \$ctx statement in flight, blocking $kind, pool of one";
    my $storage = build_storage(1);
    my %seen;
    my $r = bounded(sub {
      $storage->txn_do(sub {
        my ($ctx) = @_;
        my $flying = $ctx->select_async('thing', \@COLS, { name => 'in-txn' });
        my $ok = eval { $block->($storage); 1 };
        $seen{error}  = $ok ? '' : "$@";
        $seen{queued} = queued($storage);
        die $seen{error} unless $ok;
        return $flying;
      });
    });
    ok !$r->{hung}, "$label: nothing hangs" or diag 'it hung';
    like $seen{error}, qr/\ABlocking wait refused: .*1 more result\(s\) due/s,
      "$label: the blocking call is refused with the k44 text";
    is $seen{queued}, 0, "$label: and taken out of the pool's queue as it is refused";
    like $r->{error}, qr/more result\(s\) due/, "$label: txn_do dies with that refusal";
    pool_recovered($label, $storage, [qw( BEGIN in-txn ROLLBACK )]);
    ok !grep({ $_ eq $sent } @{ wire((conns($storage))[0]) }), "$label: the refused $kind was never sent";
    nothing_warned($label);
  }

  # The coderef catches the refusal and goes on: the transaction commits, and
  # that is the moment the queued caller used to be handed the connection.
  {
    my $label   = "k85, the coderef catches the refusal of a blocking $kind, pool of one";
    my $storage = build_storage(1);
    my %seen;
    my $r = bounded(sub {
      $storage->txn_do(sub {
        my ($ctx) = @_;
        my $flying = $ctx->select_async('thing', \@COLS, { name => 'in-txn' });
        $seen{refused} = eval { $block->($storage); 1 } ? 0 : 1;
        $seen{queued}  = queued($storage);
        return $flying;
      });
    });
    ok $r->{ok} && !$r->{hung}, "$label: the transaction commits" or diag $r->{hung} ? 'it hung' : $r->{error};
    is_deeply [ @seen{qw( refused queued )} ], [ 1, 0 ], "$label: the call was refused and nobody is queued";
    pool_recovered($label, $storage, [qw( BEGIN in-txn COMMIT )]);
    nothing_warned($label);
  }
}

# 5a'. a Future that is not chained off a queued caller is retained and
# completes, as the k44 refusal says: the blocking call finds an idle second
# connection (here: opens one) and was never queued.
{
  my $label   = 'k85, the k44 refusal of a call that was never queued, pool of two';
  my $storage = build_storage(2);
  my %seen;
  my $r = bounded(sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      my $flying = $ctx->select_async('thing', \@COLS, { name => 'in-txn' });
      $seen{error}  = eval { select_named_block($storage, 'inner'); 1 } ? '' : "$@";
      $seen{queued} = queued($storage);
      return $flying;
    });
  });
  ok $r->{ok} && !$r->{hung}, "$label: the transaction commits" or diag $r->{error};
  like $seen{error}, qr/more result\(s\) due/, "$label: the blocking call is refused";
  is $seen{queued}, 0, "$label: it was not queued";
  settle();
  is_deeply [ map { wire($_) } conns($storage) ], [ [qw( BEGIN in-txn COMMIT )], ['inner'] ],
    "$label: the refused call still completes, on the other connection -- it cancels nothing";
  is $storage->pool->available, 2, "$label: both are idle";
  nothing_warned($label);
}

# 5b. the same, in a convergent whose first component is the queued call and
# whose other is a statement on the wire in another connection: the queued one
# is taken out and never runs; the statement already sent completes and gives
# its connection back.
{
  my $label   = 'k85, a convergent of a queued call and a statement in flight, pool of two';
  my $storage = build_storage(2);
  my $slow    = select_named($storage, 'slow');   # connection 1, in flight
  my %seen;
  my $r = bounded(sub {
    $storage->txn_do(sub {                         # connection 2
      my ($ctx) = @_;
      my $flying = $ctx->select_async('thing', \@COLS, { name => 'in-txn' });
      my $queued = select_named($storage, 'queued-call');
      $seen{waiting} = queued($storage);
      $seen{error}   = eval { $EVF->needs_all($queued, $slow)->get; 1 } ? '' : "$@";
      $seen{queued}  = queued($storage);
      return $flying;
    });
  });
  ok $r->{ok} && !$r->{hung}, "$label: the transaction commits" or diag $r->{hung} ? 'it hung' : $r->{error};
  is $seen{waiting}, 1, "$label: (the call was queued: both connections checked out)";
  like $seen{error}, qr/more result\(s\) due/, "$label: the wait is refused with the k44 text";
  is $seen{queued}, 0, "$label: the queued call is out of the queue";
  settle() for 1 .. 3;   # the statement named slow* is answered after $EV::Pg::SLOW
  is_deeply [ map { wire($_) } conns($storage) ], [ ['slow'], [qw( BEGIN in-txn COMMIT )] ],
    "$label: the queued call never ran; the statement on the wire did complete";
  is $storage->pool->available, 2, "$label: both are idle";
  nothing_warned($label);
}

# 5c. a chain that catches the failure of the queued caller: the wait is still
# refused (k44 speaks), the call is still not run.
{
  my $label   = 'k85, a chain that catches the failure, pool of one';
  my $storage = build_storage(1);
  my %seen;
  my $r = bounded(sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      my $flying = $ctx->select_async('thing', \@COLS, { name => 'in-txn' });
      my $caught = select_named($storage, 'inner')->else(sub { $EVF->done('caught') });
      $seen{error}  = eval { $caught->get; 1 } ? '' : "$@";
      $seen{caught} = $caught->is_done ? $caught->get : 'not done';
      $seen{queued} = queued($storage);
      return $flying;
    });
  });
  ok $r->{ok} && !$r->{hung}, "$label: the transaction commits" or diag $r->{hung} ? 'it hung' : $r->{error};
  like $seen{error}, qr/more result\(s\) due/, "$label: the wait is refused";
  is_deeply [ @seen{qw( caught queued )} ], [ 'caught', 0 ], "$label: the chain caught the failure; nobody is queued";
  pool_recovered($label, $storage, [qw( BEGIN in-txn COMMIT )]);
  nothing_warned($label);
}

# 5d. a callback of the failed waiter dies: the pool is in order regardless.
{
  my $label   = 'k85, a callback on the queued caller dies when it is failed, pool of one';
  my $storage = build_storage(1);
  my %seen;
  my $r = bounded(sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      my $flying = $ctx->select_async('thing', \@COLS, { name => 'in-txn' });
      my $queued = select_named($storage, 'inner');
      $queued->on_fail(sub { die "callback of the failed waiter died\n" });
      $seen{error} = eval { $queued->get; 1 } ? '' : "$@";
      return $flying;
    });
  });
  ok !$r->{hung}, "$label: nothing hangs";
  like $seen{error}, qr/more result\(s\) due/, "$label: the wait is still refused with the k44 text";
  pool_recovered($label, $storage, [qw( BEGIN in-txn COMMIT )]);
  @warnings = grep { !/callback of the failed waiter died/ } @warnings;
  nothing_warned($label);
}

# 5e. the loop runs dry (karr k86). A transaction holds the pool's one
# connection, its coderef returned a Future nobody settles yet, nothing is in
# flight and no callback runs: a blocking call is queued, the loop has nothing
# left, and the wait dies. The queued caller must not outlive it.
#
# Dry needs a loop with no timer in it. Core's acquire_timeout (default 30
# seconds, core k397) arms one for every queued caller, so under the default the
# loop is never dry and the caller's wait is bounded by that timer instead (5f).
# This case says "no timeout" with acquire_timeout => 0, which is how a program
# gets the dry loop back.
{
  my $label   = 'k86, the loop runs dry under a queued blocking call, pool of one';
  my $storage = build_storage(1, acquire_timeout => 0);
  my $gate    = $EVF->new;
  my $txn     = $storage->txn_do_async(sub { return $gate });
  settle();   # BEGIN is answered and the coderef has returned
  my $r = bounded(sub { select_named_block($storage, 'inner') });
  ok !$r->{hung}, "$label: the blocking call does not hang" or diag 'it hung';
  ok !$r->{ok}, "$label: it dies";
  like $r->{error}, qr/is pending and the EV loop has nothing left that could complete it/,
    "$label: with the dry-loop text";
  is queued($storage), 0, "$label: nobody is left queued for the connection";

  $gate->done('committed');
  ok eval { bounded(sub { $txn->get })->{ok} }, "$label: the transaction ends once its Future is settled";
  pool_recovered($label, $storage, [qw( BEGIN COMMIT )]);
  nothing_warned($label);
}

# 5f. the same wait with core's acquire_timeout (core k397): the timer in the
# loop is what ends it. The blocking call fails with the pool's own message
# after the timeout, long before the 1 second watchdog, and nobody is left
# queued.
{
  my $label   = 'k397, the same wait under acquire_timeout, pool of one';
  my $storage = build_storage(1, acquire_timeout => 0.2);
  my $gate    = $EVF->new;
  my $txn     = $storage->txn_do_async(sub { return $gate });
  settle();
  my $r = bounded(sub { select_named_block($storage, 'inner') });
  ok !$r->{hung}, "$label: the blocking call does not hang" or diag 'it hung';
  ok !$r->{ok}, "$label: it dies";
  like $r->{error}, qr/no pool connection within 0\.2 seconds/, "$label: with the pool's timeout message";
  is queued($storage), 0, "$label: nobody is left queued for the connection";

  $gate->done('committed');
  ok eval { bounded(sub { $txn->get })->{ok} }, "$label: the transaction ends once its Future is settled";
  pool_recovered($label, $storage, [qw( BEGIN COMMIT )]);
  nothing_warned($label);
}

done_testing;
