use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mocks' sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# OFFLINE test for karr k26 (core k230, core ADR 0047 addenda 2026-09-27): a
# query that fails because its connection died must not leave that connection
# in the pool.
#
# WHY IT MATTERS. The pool cannot see a connection die. Its only health signal
# is the readiness Future, which resolved once when the connection came up. So
# after the server drops a session, release() puts the dead connection back on
# the idle list, and the next acquire hands it to a caller whose query fails the
# same way -- in a pool of one, every later caller's does. Core k230 gave the
# pool _mark_connection_dead: reported before the release, the release retires
# the connection and a queued caller gets a fresh one. Which errors mean "dead"
# is the driver's knowledge, so this transport asks a driver seam,
# _conn_error_is_fatal($conn, $error), on every failed query and reports on a
# true answer.
#
# WHAT IS REAL. The whole transport: _query_async, _query_async_pinned,
# _await_query_result, _mark_dead_on_fail, _release_on_ready, the Future::IO
# watcher seam on a real pipe, the real DBIO::Async::Pool with core's release,
# _mark_connection_dead and _retire_in_use_connection, and core's real
# txn_do_async. The pool only records its releases. The mocks own the
# DB-specific seams and nothing else, which section 0 pins.
#
# THE MOCK SERVER. A connection carries a "socket" (>= 0 while connected). A
# query naming KILL, or the table "doomed", kills the session: the collect
# gives the socket up (-1, what libpq does) and fails with a connection error.
# A query naming BAD fails with a statement error the session survives. Any
# query on a connection whose socket is gone fails at dispatch -- what a real
# DBD does with a dead handle.
#
# THE CLASSIFIER (Classify22) answers the way the seam's contract asks: from
# local state only, socket < 0, and records every call.

# --- RecPool22: the real pool, with every release recorded ------------------

{
  package RecPool22;
  use base 'DBIO::Async::Pool';

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

# --- Dead22: the DB-specific seams over a pipe, no classifier ---------------

{
  package Dead22;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;
  use Scalar::Util ();

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  # What a transaction context's CRUD needs from its owning storage (as in
  # t/14): this mock is its own owner, and proves ownership the way core does.
  sub _owner_storage { $_[0] }
  sub _assert_async_context_owner {
    my ($self, $ctx) = @_;
    die "async context does not belong to this storage generation\n"
      unless Scalar::Util::refaddr($self->_context_owner_token)
          == Scalar::Util::refaddr($ctx->_context_owner_token);
    return $ctx;
  }
  sub _select_args { my ($self, @args) = @_; return ('select', @args) }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { id => ++$self->{_next_id}, r => $r, w => $w, socket => 7 };
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{shutdown} }, $conn->{id};
    close $conn->{r};
    close $conn->{w};
  }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= do {
      my $errors = $self->{pool_errors} = [];
      RecPool22->new(
        storage  => $self,
        conninfo => $self->{_conninfo},
        size     => $self->{_pool_size},
        on_error => $self->{on_error_dies}
          ? sub { die "on_error itself broke\n" }
          : sub { push @$errors, $_[0] },
      );
    };
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, { sql => $sql, conn => $conn };
    die "no connection to the server\n" if $conn->{socket} < 0;
    $conn->{last_sql} = $sql;
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    my $sql = $conn->{last_sql};
    if ($sql =~ /\bKILL\b|\bdoomed\b/) {
      $conn->{socket} = -1;
      return Future->fail("server closed the connection unexpectedly\n",
        dbio => 'lost');
    }
    return Future->fail("syntax error at or near BAD\n") if $sql =~ /\bBAD\b/;
    return Future->done([ 'row-for', $sql, $conn->{id} ]);
  }
}

# --- Classify22: the same driver, with the seam filled ----------------------

{
  package Classify22;
  our @ISA = ('Dead22');

  sub _conn_error_is_fatal {
    my ($self, $conn, @failure) = @_;
    push @{ $self->{asked} }, [ $conn, @failure ];
    die "classifier broke\n" if $self->{classifier_dies};
    return $conn->{socket} < 0;
  }
}

sub new_storage {
  my ($class, %opt) = @_;
  my $storage = $class->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(wire shutdown asked);
  $storage->{$_} = $opt{$_} for keys %opt;
  # pool_size 1: the failed query held the pool's ONLY connection, so what the
  # next acquire gets tells retired-and-respawned from put-back apart.
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# Drive the loop until the Future settles, without dying on a failure.
sub settle { my $f = shift; eval { $f->get }; return $f }

# The same for a query that waited for the pool: it hangs off a pool waiter,
# a plain Future that knows no loop and so cannot ->get while pending. Turn
# the Future::IO loop by hand until it settles.
sub drive {
  my $f = shift;
  for (1 .. 50) { last if $f->is_ready; Future::IO->sleep(0)->get }
  return $f;
}

sub sqls { [ map { $_->{sql} } @{ $_[0]->{wire} } ] }

# ---------------------------------------------------------------------------
# 0. The guard that gives every other assertion its meaning: the mocks
#    override the DB-specific seams and NOTHING of the report-and-release
#    path, and the pool nothing but the recording release.
# ---------------------------------------------------------------------------

for my $method (qw(_query_async _query_async_pinned _await_query_result
                   _mark_dead_on_fail _mark_if_fatal _release_on_ready)) {
  is refaddr(Classify22->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "Classify22 does NOT override $method -- the transport itself runs";
}
is refaddr(Dead22->can('_conn_error_is_fatal')),
   refaddr(DBIO::Async::Storage->can('_conn_error_is_fatal')),
  'Dead22 keeps the default _conn_error_is_fatal -- the "no classifier" case';
isnt refaddr(Classify22->can('_conn_error_is_fatal')),
     refaddr(DBIO::Async::Storage->can('_conn_error_is_fatal')),
  'Classify22 fills _conn_error_is_fatal -- the "driver classifies" case';
for my $method (qw(_mark_connection_dead _retire_in_use_connection acquire)) {
  is refaddr(RecPool22->can($method)), refaddr(DBIO::Storage::PoolBase->can($method)),
    "RecPool22 does NOT override $method -- core's pool decides";
}

# ---------------------------------------------------------------------------
# 1. The driver says dead: the connection is retired on its release, and the
#    next query gets a fresh one. The caller still sees what went wrong.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify22');
  my $pool    = $storage->pool;

  my $f = settle($storage->_query_async('KILL', []));

  ok $f->is_failed, 'fatal: the query that lost its connection fails';
  is scalar $f->failure, "server closed the connection unexpectedly\n",
    'fatal: ... with its own error -- the report changes nothing the caller sees';

  is_deeply $pool->{release_log}, [1],
    'fatal: the connection was handed back once, as ever';
  is_deeply $storage->{shutdown}, [1],
    'fatal: ... and that release retired it: shut down, once';
  is $pool->size, 0,
    'fatal: ... and it no longer counts against the pool size';

  my $g = settle($storage->_query_async('SELECT 2', []));
  ok $g->is_done, 'fatal: the next query succeeds';
  is $g->is_done ? $g->get->[2] : undef, 2,
    'fatal: ... on a freshly spawned connection, not the dead one';
  is $storage->{_next_id}, 2,
    'fatal: ... exactly one connection was spawned to replace it';
}

# ---------------------------------------------------------------------------
# 1b. The ordering, which the outcome above cannot show on its own: a dead
#     connection marked AFTER its release would already be idle, and core
#     retires an idle one at once -- the same end state. It differs when a
#     caller is QUEUED for the slot. Report first, and the release retires the
#     connection and the waiter gets a fresh one. Release first, and the dead
#     connection goes straight to the waiter, whose query then fails too.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify22');
  my $pool    = $storage->pool;

  my $killed = $storage->_query_async('KILL', []);
  my $queued = $storage->_query_async('SELECT 2', []);
  ok !$queued->is_ready,
    'ordering: the second query waits -- the pool of one is checked out';

  settle($killed);
  drive($queued);

  ok $killed->is_failed, 'ordering: the first query lost its connection';
  ok $queued->is_done,
    'ordering: the queued query succeeds -- it was not handed the dead '
    . 'connection';
  is $queued->is_done ? $queued->get->[2] : undef, 2,
    'ordering: ... it ran on a fresh connection spawned for its slot';
  is_deeply [ map { $_->{conn}{id} } @{ $storage->{wire} } ], [1, 2],
    'ordering: nothing but the fatal query ever ran on connection 1';
  is_deeply $storage->{shutdown}, [1],
    'ordering: the dead connection was retired, once';
}

# ---------------------------------------------------------------------------
# 2. No classifier, or a classifier that says the session lives: the
#    connection goes back to the idle list, exactly as before the seam.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Dead22');
  my $pool    = $storage->pool;

  my $f = settle($storage->_query_async('KILL', []));
  ok $f->is_failed, 'default: the query fails';
  is_deeply $storage->{shutdown}, [],
    'default: nothing is retired -- the seam answers false unless a driver '
    . 'fills it';
  is $pool->available, 1, 'default: the connection is back on the idle list';
  is $pool->acquire->get->{id}, 1,
    'default: ... and handed out again, dead or not: without a classifier the '
    . 'behaviour is the one from before k26';
}

{
  my $storage = new_storage('Classify22');
  my $pool    = $storage->pool;

  my $f = settle($storage->_query_async('BAD', []));
  is scalar $f->failure, "syntax error at or near BAD\n",
    'not fatal: the statement error reaches the caller';
  is scalar @{ $storage->{asked} }, 1, 'not fatal: the seam was asked';
  is_deeply $storage->{shutdown}, [],
    'not fatal: the connection is not retired -- the session survived';

  my $g = settle($storage->_query_async('SELECT 2', []));
  is $g->is_done ? $g->get->[2] : undef, 1,
    'not fatal: the next query runs on the same connection';
  is $storage->{_next_id}, 1, 'not fatal: nothing was spawned';
}

# ---------------------------------------------------------------------------
# 3. What the seam is handed: the connection the query ran on, and the
#    Future's failure -- message first, then its category and details.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify22');
  settle($storage->_query_async('KILL', []));

  is scalar @{ $storage->{asked} }, 1, 'args: the seam was asked once';
  my ($conn, @failure) = @{ $storage->{asked}[0] };
  is refaddr($conn), refaddr($storage->{wire}[0]{conn}),
    'args: ... about the very connection the query ran on';
  is_deeply \@failure,
    [ "server closed the connection unexpectedly\n", 'dbio', 'lost' ],
    'args: ... with the error the query failed with, then the category and '
    . 'details';
}

# ---------------------------------------------------------------------------
# 4. A transaction. Its connection is pinned: the queries run through
#    _query_async_pinned, and core's finalizer makes the one hand-back, after
#    the ROLLBACK. A report from the pinned path turns that release into a
#    retirement.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify22');
  my $pool    = $storage->pool;

  my $txn_conn;
  my $f = settle($storage->txn_do_async(sub {
    my ($ctx) = @_;
    $txn_conn = $ctx->txn_conn;
    return $ctx->select_async('doomed', ['*'], {});
  }));

  ok $f->is_failed, 'txn: the transaction fails';
  like scalar $f->failure, qr/server closed the connection unexpectedly/,
    'txn: ... with the error that killed its connection';
  my $sqls = sqls($storage);
  is scalar @$sqls, 2,
    'txn: only BEGIN and the doomed statement reached the wire -- core '
    . 'issues no ROLLBACK on a connection reported dead (core k274)';
  is $sqls->[0], 'BEGIN', 'txn: ... the first was BEGIN';
  like $sqls->[1], qr/FROM doomed/, 'txn: ... the second the doomed one';
  unlike scalar $f->failure, qr/Rollback failed/,
    'txn: ... and no ROLLBACK went out on the dead connection, so the failure '
    . 'is the original error and names no rollback (core k274)';
  is scalar @{ $storage->{asked} }, 1,
    'txn: the seam was asked once -- there is no ROLLBACK for it to classify';

  is_deeply $pool->{release_log}, [1],
    'txn: the finalizer handed the connection back once';
  is_deeply $storage->{shutdown}, [1],
    'txn: ... and that release retired it instead of idling it';

  my $g = settle($storage->_query_async('SELECT 2', []));
  is $g->is_done ? $g->get->[2] : undef, 2,
    'txn: the next query runs on a fresh connection';
}

# ---------------------------------------------------------------------------
# 5. A classifier that throws. Treated as dead -- nothing can vouch for the
#    connection -- and reported to the pool's on_error so the broken seam is
#    not silent. The throw goes nowhere else: the caller gets the query's own
#    error, and the connection is still handed back exactly once (a die in a
#    Future callback would skip every callback after it, the release among
#    them).
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify22', classifier_dies => 1);
  my $pool    = $storage->pool;

  my @warnings;
  my $f = do {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $storage->_query_async('BAD', []);
  };
  my $err = do {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { $f->get; 1 } ? undef : $@;
  };

  is $err, "syntax error at or near BAD\n",
    'throwing classifier: the caller sees the query\'s own error, not the '
    . 'classifier\'s';
  is scalar @{ $storage->{asked} }, 1, 'throwing classifier: it was asked once';
  is scalar @{ $storage->{pool_errors} }, 1,
    'throwing classifier: the throw went to the pool\'s on_error, once';
  like $storage->{pool_errors}[0],
    qr/_conn_error_is_fatal died.*treated as dead.*classifier broke/s,
    'throwing classifier: ... naming the seam, the consequence and the error';
  is_deeply \@warnings, [], 'throwing classifier: ... and nothing was warned';

  is_deeply $pool->{release_log}, [1],
    'throwing classifier: the connection was handed back exactly once';
  is_deeply $storage->{shutdown}, [1],
    'throwing classifier: ... and retired: a connection nothing vouches for '
    . 'is not handed out again';

  my $g = settle($storage->_query_async('SELECT 2', []));
  is $g->is_done ? $g->get->[2] : undef, 2,
    'throwing classifier: the next query runs on a fresh connection';
}

# 5b. ... and when the pool's on_error dies as well, the report still is not
#     lost: it is warned.
{
  my $storage = new_storage('Classify22', classifier_dies => 1,
    on_error_dies => 1);
  my $pool    = $storage->pool;

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    settle($storage->_query_async('BAD', []));
  }

  is scalar @warnings, 1, 'dying on_error: the report was warned instead';
  like $warnings[0], qr/_conn_error_is_fatal died.*classifier broke/s,
    'dying on_error: ... with the same report';
  is_deeply $pool->{release_log}, [1],
    'dying on_error: the connection was still handed back exactly once';
  is_deeply $storage->{shutdown}, [1], 'dying on_error: ... and retired';
}

# ---------------------------------------------------------------------------
# 6. A query that does not fail never asks: not a pooled one, not a pinned
#    one, not a whole committed transaction -- and not a cancelled one, whose
#    outcome says nothing about the connection. The seam is paid for only on
#    the failure path.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify22');
  my $pool    = $storage->pool;

  ok settle($storage->_query_async('SELECT 1', []))->is_done,
    'success: a pooled query succeeds';

  my $conn = $pool->acquire->get;
  ok settle($storage->_query_async_pinned($conn, 'SELECT 2', []))->is_done,
    'success: a pinned query succeeds';
  $pool->release($conn);

  ok settle($storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async('artist', ['*'], {});
  }))->is_done, 'success: a transaction commits';

  is_deeply $storage->{asked}, [],
    'success: the seam was never asked';
}

{
  my $storage = new_storage('Classify22');
  my $f = $storage->_query_async('SELECT 1', []);
  $f->cancel;
  is_deeply $storage->{asked}, [],
    'cancelled: a cancelled query does not ask the seam';
  is_deeply $storage->{pool}{release_log}, [1],
    'cancelled: ... and hands its connection back, as before';
}

# ---------------------------------------------------------------------------
# 7. A connection the pool does not hold -- the listen connection an emulated
#    _listen_drain queries through _query_async_pinned is one. The seam is
#    asked, the pool ignores the report, and nothing else happens: no
#    shutdown, no error.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify22');
  my $outside = $storage->_create_pool_connection;   # built as _listen_open would

  my @warnings;
  my $f = do {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    settle($storage->_query_async_pinned($outside, 'KILL', []));
  };

  is scalar $f->failure, "server closed the connection unexpectedly\n",
    'outside the pool: the query fails with its own error';
  is scalar @{ $storage->{asked} }, 1, 'outside the pool: the seam was asked';
  is_deeply $storage->{shutdown}, [],
    'outside the pool: the report changed nothing -- the pool does not hold '
    . 'the connection, so it neither retires nor shuts it down';
  is $storage->pool->size, 0, 'outside the pool: ... and holds nothing';
  is_deeply $storage->{pool_errors}, [], 'outside the pool: no pool error';
  is_deeply \@warnings, [], 'outside the pool: no warning';
}

done_testing;
