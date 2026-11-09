use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k53: a blocking call that is queued for a pooled
# connection, made inside callbacks that hold every connection of that pool, is
# REFUSED with an exception -- it does not hang.
#
# WHY: every blocking method is ->get on its *_async sibling, and
# DBIO::MySQL::EV::Future's get runs the EV loop until the Future is ready. A
# txn_do coderef runs inside a callback of the transaction's connection, and
# the transaction gives that connection back only after the coderef has
# returned. A blocking call on the STORAGE there (not on the transaction
# context) needs another connection; with every connection of the pool held
# that way it is queued for one that cannot come back while it waits. Nothing
# is sent, nothing is in flight, and the handle's own watcher keeps the loop
# alive: a silent hang. karr k48 refuses a wait for a statement queued on the
# SAME connection; this is the wait for ANOTHER connection that cannot come.
#
# What this file claims:
#   1. Refused, not hung, with a refusal that says what to do instead (the
#      transaction context, the *_async methods chained with ->then, a larger
#      pool_size):
#      a. pool of one: a sync select on the storage in a txn_do coderef, without
#         and with bind values;
#      b. pool of one: a sync insert on the storage there;
#      c. pool of one: a nested sync txn_do on the storage there -- its coderef
#         never runs;
#      d. pool of two: a sync select in the coderef of a txn_do nested in the
#         coderef of another -- the call chain holds both connections;
#      e. pool of one: a sync select on the storage in a then on a statement of
#         the transaction (txn_do_async), where the coderef has returned but
#         the transaction still holds the connection whose callback runs;
#      f. pool of one: the pool's only connection still has a statement in
#         flight when the wait begins (an unawaited $ctx->insert_async); the
#         wait is refused once that statement has been answered.
#   2. The refused call does not run, then or later: it is taken out of the
#      pool's queue, so a refused insert writes nothing. The transaction is
#      rolled back (no COMMIT), every connection goes back to the pool, and the
#      next call works. No "lost a sequence Future".
#   3. No refusal where the wait can end:
#      a. pool of two, the transaction holds one: the sync call takes the other;
#      b. pool of two, the other connection is busy with an independent
#         statement in flight: the sync call waits for it and returns;
#      c. pool of one, in a then on the connection: a sync call queued behind a
#         statement in flight on that very connection waits and returns;
#      d. top level: a sync call queued behind a statement in flight returns;
#      e. top level: a sync call queued behind a transaction that holds the only
#         connection with nothing in flight -- its coderef returned a Future a
#         timer settles -- returns once the transaction has committed;
#      f. in a txn_do coderef, with an unawaited storage call queued for the
#         transaction's connection: a blocking wait for something else and a
#         blocking call on the transaction context both return, the transaction
#         commits, and the queued call runs after it.
#
# 1 and 2 fail without the refusal: every case in 1 hangs -- 1f dies with "the
# EV loop has nothing left" instead, leaving its caller queued and the pool
# wedged -- the watchdog fails the queued call, and the refusal assertions
# fail. 3 guards against over-refusal. It fails if the refusal takes an
# exhausted pool for a hopeless one (3b, 3c, 3d, 3e), if it ignores a statement
# in flight on a connection whose callback runs (3c), if it ignores whether a
# callback of the connection runs at all (3d, 3e), or if it refuses every blocking
# wait made while some call is queued (3f); 3a fails if a storage call in a
# txn coderef is refused as such.
#
# QueueMDB stands in for EV::MariaDB, as in t/27-blocking-in-callback-mock.t: a
# callback of a handle runs with the handle's depth raised; query() queues, and
# sends at once only when the handle is idle and its depth is 0; the queue is
# sent after one of the handle's callbacks returns or an exclusive operation of
# it completes; prepare / execute / close_stmt are exclusive and start at once;
# while anything is pending on the handle it keeps an active watcher, and that
# watcher is still active while the callback of its last answer runs -- which
# is what keeps the loop of a hanging wait alive. A statement on a table named
# slow_* is answered late. Completions arrive on EV timers.
#
# Every wait is bounded by an EV watchdog with keepalive(0): a wait that hangs
# sits in libev's C code, where a Perl signal handler never runs (karr k46).
# When it fires it fails every queued caller and everything pending on every
# fake handle, so a hang shows up as a failed assertion and the file goes on.
# The alarm below has no handler: should the watchdog itself fail, the signal's
# default action ends the process, so a hang never outlives the test.

use EV;
use Scalar::Util ();
use DBIO::MySQL::EV::Future;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

alarm 120;

my $LIMIT   = 2;
my $SLOW    = 0.2;
my $REFUSED = qr/\QBlocking wait refused\E/;
my $ADVICE  = qr/\$ctx->.*_async.*->then.*pool_size/s;
my $SEL     = 'SELECT `id`, `name` FROM `artist`';
my $SEL_ID  = 'SELECT `id`, `name` FROM `artist` WHERE ( `id` = ? )';
my $INS     = 'INSERT INTO `artist` (`name`) VALUES (?)';
my $LII     = 'SELECT LAST_INSERT_ID()';
my @COLS    = qw( id name );

{
  package QueueMDB;
  use Scalar::Util ();
  use Socket ();

  our @ALL;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      connected  => 0,
      depth      => 0,       # EV::MariaDB's callback_depth
      op         => undef,   # the exclusive operation in progress
      queue      => [],      # queries not sent yet: [ $sql, $cb ]
      sent       => [],      # queries sent, result not delivered yet
      wire       => [],      # every statement the server received, in order
      stmts      => {},
      next_stmt  => 0,
    }, $class;
    # A live session: a real socket with nothing to read, which is what the
    # transport asks a handle about after a failed statement (karr k55).
    socketpair($self->{sock}[0], $self->{sock}[1], Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    push @ALL, $self;
    Scalar::Util::weaken($ALL[-1]);
    _later(sub { $self->{connected} = 1; $self->_callback($self->{on_connect}) });
    return $self;
  }

  sub is_connected  { $_[0]{connected} }
  # As strict as EV::MariaDB 0.08 (karr k67).
  sub close_async   { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; Carp::croak('not connected') unless $_[0]{connected}; $_[1]->(1); return }
  sub finish        { Carp::croak('Usage: EV::MariaDB::finish(self)') unless @_ == 1; return }
  sub socket        { fileno $_[0]{sock}[0] }
  sub pending_count { ($_[0]{op} ? 1 : 0) + @{ $_[0]{queue} } + @{ $_[0]{sent} } }

  sub _later {
    my ($cb, $after) = @_;
    my $t;
    $t = EV::timer($after // 0.001, 0, sub { undef $t; $cb->() });
    return;
  }

  sub _delay { $_[0] =~ /`slow_/ ? $SLOW : 0.001 }

  # The handle's own watcher: active while anything is pending on it. It is
  # re-evaluated only after a callback has returned, so it is still active
  # while the callback of the last answer runs.
  sub _watch {
    my ($self) = @_;
    if ($self->{op} || @{ $self->{queue} } || @{ $self->{sent} }) {
      $self->{watch} ||= EV::timer(0.05, 0.05, sub { });
    }
    else {
      delete $self->{watch};
    }
    return;
  }

  # A callback of the handle: depth raised while it runs, an exception is
  # caught and warned (G_EVAL), and afterwards whatever was queued is sent.
  sub _callback {
    my ($self, $cb, @args) = @_;
    $self->{depth}++;
    eval { $cb->(@args) if $cb; 1 } or warn "QueueMDB: exception in callback: $@";
    $self->{depth}--;
    $self->_pump;
    return;
  }

  sub _pump {
    my ($self) = @_;
    unless ($self->{op}) {
      for my $q (splice @{ $self->{queue} }) {
        push @{ $self->{wire} }, $q->[0];
        push @{ $self->{sent} }, $q;
      }
      $self->_read_next;
    }
    $self->_watch;
    return;
  }

  sub _read_next {
    my ($self) = @_;
    return if $self->{reading} || !@{ $self->{sent} };
    $self->{reading} = 1;
    _later(sub {
      $self->{reading} = 0;
      my $q = shift @{ $self->{sent} } or return;
      $self->_callback($q->[1], $self->_answer($q->[0]));
      $self->_read_next;
    }, _delay($self->{sent}[0][0]));
    return;
  }

  sub _answer {
    my ($self, $sql) = @_;
    return ([ [ 7 ] ])         if $sql =~ /LAST_INSERT_ID/;
    return ([ [ 1, 'one' ] ])  if $sql =~ /^SELECT/;
    return (1)                 if $sql =~ /^(?:INSERT|UPDATE|DELETE)/;
    return (0);
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    die "not connected\n" unless $self->{connected};
    die "cannot queue query: exclusive operation in progress\n" if $self->{op};
    push @{ $self->{queue} }, [ $sql, $cb ];
    if ($self->{depth}) { $self->_watch } else { $self->_pump }
    return;
  }

  sub _check_ready {
    my ($self) = @_;
    die "not connected\n" unless $self->{connected};
    die "another operation is in progress\n" if $self->{op};
    die "cannot start operation while pipeline results are pending\n" if @{ $self->{sent} };
    return;
  }

  sub _start {
    my ($self, $what, $cb, $answer, $after) = @_;
    $self->{op} = $what;
    $self->{op_cb} = $cb;
    $self->_watch;
    _later(sub {
      return unless $self->{op};
      undef $self->{op};
      $self->_callback(delete $self->{op_cb}, $answer->());
    }, $after);
    return;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    $self->_check_ready;
    $self->_start(prepare => $cb, sub {
      my $id = ++$self->{next_stmt};
      $self->{stmts}{$id} = $sql;
      return ($id);
    });
    return;
  }

  sub execute {
    my ($self, $id, $bind, $cb) = @_;
    $self->_check_ready;
    my $sql = $self->{stmts}{$id};
    push @{ $self->{wire} }, $sql;
    $self->_start(execute => $cb, sub { $self->_answer($sql) }, _delay($sql));
    return;
  }

  sub close_stmt {
    my ($self, $id, $cb) = @_;
    $self->_check_ready;
    $self->_start(close_stmt => $cb, sub { delete $self->{stmts}{$id}; return (1) });
    return;
  }

  # COM_RESET_CONNECTION, sent by the pool at the end of every borrow (karr
  # k100, core k398): exclusive like prepare, not a statement of the wire.
  sub reset_connection {
    my ($self, $cb) = @_;
    $self->_check_ready;
    $self->_start(reset_connection => $cb, sub { return (1) });
    return;
  }

  # The watchdog's way out of a hang: fail everything pending on every handle.
  sub break_all {
    my ($class, $why) = @_;
    for my $self (grep { defined } @ALL) {
      my @stuck = ( splice(@{ $self->{queue} }), splice(@{ $self->{sent} }) );
      if ($self->{op}) {
        undef $self->{op};
        push @stuck, [ undef, delete $self->{op_cb} ];
      }
      $self->_watch;
      $self->_callback($_->[1], undef, $why) for @stuck;
    }
    return;
  }
}

{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; QueueMDB->new(@_) };
}

my @STORAGES;
sub build_storage {
  my ($size) = @_;
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => $size }, {} ]);
  push @STORAGES, $storage;
  Scalar::Util::weaken($STORAGES[-1]);
  return $storage;
}

sub conns   { @{ $_[0]->pool->{_connections} } }

# The idle connections of the pool once the reset of the sessions has answered
# (karr k100, core k398): a connection is idle again after it, not at the release.
sub idle_count {
  my ($storage, $want) = @_;
  my $dog = EV::timer(2, 0, sub {});
  EV::run(EV::RUN_ONCE()) until $storage->pool->available == $want || !$dog->is_active;
  return $storage->pool->available;
}
sub queued  { scalar @{ $_[0]->pool->{_waiters} } }
sub wire    { [ @{ $_[0]{wire} } ] }

# A txn coderef hands back a Future, so its value reaches the caller whatever
# it is.
sub done_with { DBIO::MySQL::EV::Future->done(@_) }

# Run $code under the watchdog: (1, @result) when it returned, (0, $error) when
# it died. A wait still blocked after $LIMIT seconds is failed by the watchdog:
# every caller queued for a connection first, then every pending statement.
my @WARN;
sub bounded {
  my ($label, $code) = @_;
  my $dog = EV::timer($LIMIT, 0, sub {
    my $why = "watchdog: $label still blocked after ${LIMIT}s\n";
    for my $storage (grep { defined } @STORAGES) {
      my $pool = $storage->{pool} or next;
      $_->fail($why) for grep { !$_->is_ready } splice @{ $pool->{_waiters} };
    }
    QueueMDB->break_all($why);
  });
  $dog->keepalive(0);
  local $SIG{__WARN__} = sub { push @WARN, $_[0] };
  my @r;
  return (1, @r) if eval { @r = $code->(); 1 };
  return (0, $@);
}

sub no_lost_sequence {
  my ($label) = @_;
  my @lost = grep { /lost a sequence Future/ } @WARN;
  ok !@lost, "$label: no sequence Future was lost" or diag @lost;
  @WARN = ();
  return;
}

# What every refusal leaves behind: nobody queued, every connection idle, and a
# pool that serves the next call.
sub pool_recovered {
  my ($label, $storage, $size) = @_;
  is queued($storage), 0, "$label: nobody is left queued for a connection";
  my ($ok, @rows) = bounded("$label: next select", sub { $storage->select('artist', \@COLS, {}, {}) });
  ok $ok, "$label: the next select works" or diag $rows[0];
  is_deeply \@rows, [ [ 1, 'one' ] ], "$label: (with its rows)";
  is idle_count($storage, $size), $size, "$label: every connection is back in the pool";
  no_lost_sequence($label);
  return;
}

# --- 1a. pool of one: a sync select on the storage in a txn_do coderef --------
for my $case (
  [ 'without bind values', {},          $SEL    ],
  [ 'with bind values',    { id => 1 }, $SEL_ID ],
) {
  my ($what, $where, $sql) = @$case;
  my $label   = "storage select $what in a txn coderef";
  my $storage = build_storage(1);
  my $ran_on;
  my ($ok, $err) = bounded($label, sub {
    $storage->txn_do(sub {
      my @rows = $storage->select('artist', \@COLS, $where, {});
      $ran_on = 'returned';
      return done_with(\@rows);
    });
  });
  ok !$ok, "txn_do dies when its coderef makes a sync select $what on the storage (pool of one)";
  like $err, $REFUSED, 'refused: the connection it is queued for cannot come back while it waits';
  like $err, $ADVICE, 'naming the transaction context, the *_async methods with ->then, and pool_size';
  ok !defined $ran_on, 'the blocking call did not return';

  my ($h) = conns($storage);
  is_deeply wire($h), [ 'BEGIN', 'ROLLBACK' ], 'the transaction was rolled back, and the select was not sent';
  pool_recovered($label, $storage, 1);
  is scalar(grep { $_ eq $sql } @{ $h->{wire} }), 0, 'the refused select does not run later either'
    if $sql ne $SEL;
  is_deeply wire($h), [ 'BEGIN', 'ROLLBACK', $SEL ], 'the refused select does not run later either'
    if $sql eq $SEL;
}

# --- 1b. pool of one: a sync insert on the storage writes nothing -------------
{
  my $label   = 'storage insert in a txn coderef';
  my $storage = build_storage(1);
  my ($ok, $err) = bounded($label, sub {
    $storage->txn_do(sub { return done_with($storage->insert('artist', { name => 'x' })) });
  });
  ok !$ok, 'txn_do dies when its coderef makes a sync insert on the storage (pool of one)';
  like $err, $REFUSED, 'refused';

  my ($h) = conns($storage);
  pool_recovered($label, $storage, 1);
  is_deeply wire($h), [ 'BEGIN', 'ROLLBACK', $SEL ], 'the refused insert was never sent: it writes nothing';
}

# --- 1c. pool of one: a nested sync txn_do on the storage ---------------------
{
  my $label   = 'nested storage txn_do, pool of one';
  my $storage = build_storage(1);
  my $inner_ran = 0;
  my ($ok, $err) = bounded($label, sub {
    $storage->txn_do(sub {
      return done_with($storage->txn_do(sub { $inner_ran++; return done_with(1) }));
    });
  });
  ok !$ok, 'txn_do dies when its coderef starts a sync txn_do on the storage (pool of one)';
  like $err, $REFUSED, 'refused';
  is $inner_ran, 0, 'the inner coderef never ran';

  my ($h) = conns($storage);
  is_deeply wire($h), [ 'BEGIN', 'ROLLBACK' ], 'one BEGIN, rolled back: the inner transaction never began';
  pool_recovered($label, $storage, 1);
}

# --- 1d. pool of two: the call chain holds both connections -------------------
{
  my $label   = 'storage select under two nested transactions, pool of two';
  my $storage = build_storage(2);
  my ($ok, $err) = bounded($label, sub {
    $storage->txn_do(sub {
      return done_with($storage->txn_do(sub {
        return done_with([ $storage->select('artist', \@COLS, {}, {}) ]);
      }));
    });
  });
  ok !$ok, 'a sync select on the storage under two nested txn_do coderefs (pool of two) dies';
  like $err, $REFUSED, 'refused: both connections are held by the call chain';
  like $err, $ADVICE, 'with the advice';

  my ($outer, $inner) = conns($storage);
  is_deeply wire($outer), [ 'BEGIN', 'ROLLBACK' ], 'the outer transaction was rolled back';
  is_deeply wire($inner), [ 'BEGIN', 'ROLLBACK' ], 'and so was the inner one';
  pool_recovered($label, $storage, 2);
}

# --- 1e. pool of one: in a then on a statement of the transaction -------------
{
  my $label   = 'storage select in a then inside a transaction';
  my $storage = build_storage(1);
  my ($ok, $err) = bounded($label, sub {
    $storage->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->insert_async('artist', { name => 'x' })->then(sub {
        return done_with([ $storage->select('artist', \@COLS, {}, {}) ]);
      });
    })->get;
  });
  ok !$ok, 'a sync select on the storage in a then on a statement of the transaction (pool of one) dies';
  like $err, $REFUSED, 'refused: the transaction holds the connection whose callback runs';

  my ($h) = conns($storage);
  is_deeply wire($h), [ 'BEGIN', $INS, $LII, 'ROLLBACK' ], 'the transaction ran its insert and was rolled back';
  pool_recovered($label, $storage, 1);
}

# --- 1f. pool of one: refused once the statement in flight has been answered --
{
  my $label   = 'storage select behind an unawaited statement of the transaction';
  my $storage = build_storage(1);
  my $inserted;
  my ($ok, $err) = bounded($label, sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      $inserted = $ctx->insert_async('artist', { name => 'x' });
      return done_with([ $storage->select('artist', \@COLS, {}, {}) ]);
    });
  });
  ok !$ok, 'a sync select on the storage with a statement of the transaction in flight (pool of one) dies';
  like $err, $REFUSED, 'refused';
  ok $inserted && $inserted->is_done,
    'after the statement in flight was answered: the wait went on while the connection had work';

  my ($h) = conns($storage);
  is_deeply wire($h), [ 'BEGIN', $INS, $LII, 'ROLLBACK' ], 'the insert ran, the transaction was rolled back';
  pool_recovered($label, $storage, 1);
}

# --- 3a. pool of two: the sync call takes the other connection ----------------
{
  my $storage = build_storage(2);
  my ($ok, @r) = bounded('select on the other connection', sub {
    $storage->txn_do(sub { return done_with([ $storage->select('artist', \@COLS, { id => 1 }, {}) ]) });
  });
  ok $ok, 'a sync select on the storage in a txn coderef that gets ANOTHER connection returns' or diag $r[0];
  is_deeply $r[0], [ [ 1, 'one' ] ], '(its rows)';
  my ($txn, $other) = conns($storage);
  is_deeply wire($txn), [ 'BEGIN', 'COMMIT' ], 'the transaction committed';
  is_deeply wire($other), [ $SEL_ID ], 'the select ran on the other connection';
  no_lost_sequence('select on the other connection');
}

# --- 3b. pool of two: the other connection is busy, and will come back --------
{
  my $storage = build_storage(2);
  my $slow    = $storage->select_async('slow_artist', \@COLS, {}, {});
  my %seen;
  my ($ok, @r) = bounded('select behind an independent statement', sub {
    $storage->txn_do(sub {
      $seen{before} = $slow->is_ready ? 'ready' : 'pending';
      my @rows = $storage->select('artist', \@COLS, {}, {});
      $seen{after} = $slow->is_ready ? 'ready' : 'pending';
      return done_with(\@rows);
    });
  });
  ok $ok, 'a sync select on the storage in a txn coderef, queued behind an independent statement in flight, returns'
    or diag $r[0];
  is_deeply $r[0], [ [ 1, 'one' ] ], '(its rows)';
  is_deeply \%seen, { before => 'pending', after => 'ready' },
    'it waited for the independent statement, whose connection it then got';
  my ($busy, $txn) = conns($storage);
  is_deeply wire($txn), [ 'BEGIN', 'COMMIT' ], 'the transaction committed';
  is_deeply wire($busy), [ 'SELECT `id`, `name` FROM `slow_artist`', $SEL ],
    'the select ran on the connection the independent statement gave back';
  is idle_count($storage, 2), 2, 'both connections are back in the pool';
  no_lost_sequence('select behind an independent statement');
}

# --- 3c. pool of one: behind a statement in flight on the callback's connection
{
  my $storage = build_storage(1);
  my %seen;
  my ($ok, @r) = bounded('select behind a statement on the same connection', sub {
    $storage->select_async('artist', \@COLS, {}, {})->then(sub {
      my $slow = $storage->select_async('slow_artist', \@COLS, { id => 1 }, {});
      $seen{queued_behind} = $slow->is_ready ? 'ready' : 'pending';
      my @rows = $storage->select('artist', \@COLS, { id => 2 }, {});
      $seen{after} = $slow->is_ready ? 'ready' : 'pending';
      return done_with(\@rows);
    })->get;
  });
  ok $ok, 'a sync select in a then, queued behind a statement in flight on that connection, returns' or diag $r[0];
  is_deeply $r[0], [ [ 1, 'one' ] ], '(its rows)';
  is_deeply \%seen, { queued_behind => 'pending', after => 'ready' }, 'it waited for that statement';
  is idle_count($storage, 1), 1, 'the connection is back in the pool';
  no_lost_sequence('select behind a statement on the same connection');
}

# --- 3d. top level: queued behind a statement in flight -----------------------
{
  my $storage = build_storage(1);
  my $slow    = $storage->select_async('slow_artist', \@COLS, {}, {});
  my ($ok, @rows) = bounded('top-level select behind a statement', sub { $storage->select('artist', \@COLS, {}, {}) });
  ok $ok, 'a top-level sync select queued behind a statement in flight returns' or diag $rows[0];
  is_deeply \@rows, [ [ 1, 'one' ] ], '(its rows)';
  ok $slow->is_done, 'after that statement';
  no_lost_sequence('top-level select behind a statement');
}

# --- 3e. top level: behind a transaction with nothing in flight ---------------
{
  my $storage = build_storage(1);
  my $gate    = DBIO::MySQL::EV::Future->new;
  my $open    = EV::timer($SLOW, 0, sub { $gate->done('committed') });
  my $txn     = $storage->txn_do_async(sub { return $gate });
  my ($ok, @rows) = bounded('top-level select behind a transaction', sub {
    $storage->select('artist', \@COLS, {}, {});
  });
  ok $ok, 'a top-level sync select queued behind a transaction that waits for a timer returns' or diag $rows[0];
  is_deeply \@rows, [ [ 1, 'one' ] ], '(its rows)';
  ok $txn->is_done, 'after the transaction';
  my ($h) = conns($storage);
  is_deeply wire($h), [ 'BEGIN', 'COMMIT', $SEL ],
    'on the connection the transaction gave back: it held it with nothing in flight meanwhile';
  no_lost_sequence('top-level select behind a transaction');
}

# --- 3f. a queued call nobody waits for refuses nothing -----------------------
{
  my $storage = build_storage(1);
  my ($queued, %seen);
  my ($ok, @r) = bounded('waits beside a queued call', sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      $queued = $storage->select_async('artist', \@COLS, {}, {});
      $seen{queued} = queued($storage);

      my $tick = DBIO::MySQL::EV::Future->new;
      my $t    = EV::timer(0.02, 0, sub { $tick->done('tick') });
      $seen{tick} = $tick->get;

      $seen{insert} = $ctx->insert('artist', { name => 'x' });
      return done_with('committed');
    });
  });
  ok $ok, 'a txn coderef with an unawaited storage call queued for its connection returns' or diag $r[0];
  is_deeply \%seen, { queued => 1, tick => 'tick', insert => { name => 'x' } },
    'a blocking wait for something else and a blocking call on the context both returned';
  my ($got_ok, @rows) = bounded('the queued call', sub { $queued->get });
  ok $got_ok, 'the queued call ran once the transaction gave the connection back' or diag $rows[0];
  is_deeply \@rows, [ [ 1, 'one' ] ], '(its rows)';
  my ($h) = conns($storage);
  is_deeply wire($h), [ 'BEGIN', $INS, $LII, 'COMMIT', $SEL ], 'after the COMMIT, on that connection';
  no_lost_sequence('waits beside a queued call');
}

done_testing;
