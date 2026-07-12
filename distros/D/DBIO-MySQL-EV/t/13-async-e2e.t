use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  plan skip_all => 'Set DBIO_TEST_MYSQL_DSN to run integration tests'
    unless $ENV{DBIO_TEST_MYSQL_DSN};
}

BEGIN {
  eval { require EV::MariaDB; 1 }
    or plan skip_all => 'EV::MariaDB not installed';
}

# End-to-end async proof: drive the REAL DBIO::MySQL::EV facade against
# a live EV::MariaDB connection via EV::run, and assert the three defining
# async properties that no mock-based test can prove:
#
#   1. Non-blocking — a facade query call RETURNS before the EV::MariaDB has
#      answered. The Future is pending the instant the call returns; EV::run
#      is what drives it to completion.
#   2. Concurrency — N facade queries issued in a tight loop are ALL pending
#      simultaneously; EV::run drains them and each resolves with its own
#      row, with completion order decoupled from issue order.
#   3. Transaction pinning — txn_do_async pins BEGIN/COMMIT/INSERT/SELECT to
#      the SAME EV::MariaDB connection. ROLLBACK visibly undoes the INSERT
#      from a follow-up select on a fresh pool connection.
#
# EV::run driving note: the EV::MariaDB connect handshake is queued on EV
# watchables. Until EV::run is called at least once (typically
# `EV::run(EV::RUN_ONCE)` repeatedly), no FD events fire and the connect
# never completes. We therefore use an explicit pump_until($cond) helper
# rather than relying on `EV::run until $cond` (which enters EV::run once
# and may return immediately if no events are armed yet — see EV docs).

use EV;
use Future;
use Scalar::Util ();
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;
use DBIO::MySQL::EV::QueryExecutor;
use DBIO::MySQL::EV::TransactionContext;

# --- Parse DSN into EV::MariaDB-named conninfo hash --------------------------
my $dsn = $ENV{DBIO_TEST_MYSQL_DSN};

my %conninfo;
if ($dsn =~ /^dbi:(?:mysql|mysql\.rdbs|mariadb):(.+)/i) {
  my $params = $1;
  for my $pair (split /;/, $params) {
    my ($k, $v) = split /=/, $pair, 2;
    $k = 'database' if $k eq 'dbname';
    $conninfo{$k} = $v if defined $k && defined $v;
  }
}
$conninfo{user}     = $ENV{DBIO_TEST_MYSQL_USER} if $ENV{DBIO_TEST_MYSQL_USER};
$conninfo{password} = $ENV{DBIO_TEST_MYSQL_PASS} if $ENV{DBIO_TEST_MYSQL_PASS};

diag "Server: $conninfo{host} db=$conninfo{database} user=$conninfo{user}";

# Pump EV::run(RUN_ONCE) until $cond is true OR a hard timeout fires. Returns
# the number of iterations pumped; a return >= $timeout means the condition
# never held (caller decides whether to fail / skip). Default 5000 — the
# SLEEP-injected queries in Block 1 + 2 round-trip in ~50ms, so 5000
# iterations gives 100x headroom for any EV pipeline stall.
sub pump_until {
  my ($cond, $timeout) = @_;
  $timeout //= 5000;
  my $i = 0;
  while ($i++ < $timeout) {
    return $i if $cond->();
    EV::run(EV::RUN_ONCE);
  }
  return $i;
}

# --- Build a real facade Storage --------------------------------------------

# Concurrency block (below) fires N=16 facade calls back-to-back. Each call
# acquires its own connection from the pool, so the pool must have at
# least N slots — otherwise some calls hand back already-resolved Futures
# from a shared idle conn and the "all 16 pending before EV::run" assertion
# fails for trivial reasons (a re-used idle conn already had its connect
# handshake driven by EV::run, so the very first query on it can resolve
# without a fresh EV::run cycle — looks like synchronous resolution).
my $POOL_SIZE = 16;

my $storage = DBIO::MySQL::EV::Storage->new(undef);
$storage->connect_info([ { %conninfo, pool_size => $POOL_SIZE }, {} ]);

# The pool returns a done Future IMMEDIATELY from acquire — it hands off the
# EV::MariaDB handle, but the handle is not yet connected at the protocol
# level (server_version is 0). We pump EV::run until the connect handshake
# completes (signalled by server_version becoming non-zero).
my @warm_conns;
for my $slot (1 .. $POOL_SIZE) {
  my $warm = $storage->pool->acquire;
  ok $warm->is_ready, "pool slot $slot: pool->acquire returns a ready Future synchronously (handle handed off)";
  my $warm_conn = $warm->get;
  isa_ok $warm_conn, 'EV::MariaDB', "pool slot $slot: acquired handle is an EV::MariaDB";
  push @warm_conns, $warm_conn;
}

# Drive EV::run until ALL warm-up conns complete their connect handshake.
my $pumped = pump_until(sub {
  scalar(grep { $_->server_version && $_->server_version > 0 } @warm_conns) == $POOL_SIZE
});
diag "Pumped $pumped iterations to complete $POOL_SIZE connect handshakes";

unless (scalar(grep { $_->server_version && $_->server_version > 0 } @warm_conns) == $POOL_SIZE) {
  $storage->disconnect;
  plan skip_all => "EV::MariaDB connect never completed after $pumped pump iterations";
}

diag "Server version: " . $warm_conns[0]->server_version;

# Put the warm connections back so the facade can reuse them.
$storage->pool->release($_) for @warm_conns;

# --- Schema setup: real (non-temporary) table so it survives across the
#     multiple pooled connections the concurrency block acquires. We pick a
#     table name unlikely to clash with anything else in this DB and drop
#     it at the end of the test.
my $TABLE = "_dbio_async_e2e_test";

{
  my $f = $storage->txn_do_async(sub {
    my ($txn) = @_;
    return $txn->_query_async(
      "CREATE TABLE IF NOT EXISTS $TABLE ("
      . "id INT AUTO_INCREMENT, "
      . "label VARCHAR(64) NOT NULL, "
      . "value INT NOT NULL, "
      . "PRIMARY KEY (id)"
      . ") ENGINE=InnoDB",
      []
    );
  });
  pump_until(sub { $f->is_ready });
  ok $f->is_ready && !$f->is_failed, "created $TABLE"
    or diag "create failure: " . ($f->failure // 'unknown');
}

# Truncate so reruns in the same DB don't accumulate rows.
{
  my $f = $storage->txn_do_async(sub {
    my ($txn) = @_;
    return $txn->_query_async("TRUNCATE TABLE $TABLE", []);
  });
  pump_until(sub { $f->is_ready });
  ok $f->is_ready && !$f->is_failed, "truncated $TABLE"
    or diag "truncate failure: " . ($f->failure // 'unknown');
}

# Populate with 16 rows. Each row is its own one-insert transaction so we
# never have multiple in-flight queries on a single pinned EV::MariaDB
# connection (which would trip EV::MariaDB's "exclusive operation in
# progress" guard — a property of the EV::MariaDB API, not of this
# driver). The concurrency block below is what actually proves
# in-flight parallelism, and it does so across MULTIPLE pool connections
# (one acquire per facade call).
for my $i (1 .. 16) {
  my $f = $storage->txn_do_async(sub {
    my ($txn) = @_;
    return $txn->insert_async(
      $TABLE,
      { label => "row-$i", value => $i * 10 },
    );
  });
  pump_until(sub { $f->is_ready });
  ok $f->is_ready && !$f->is_failed, "inserted row-$i"
    or diag "populate-$i failure: " . ($f->failure // 'unknown');
}

# =============================================================================
# BLOCK 1 — NON-BLOCKING PROOF
# A single select_async MUST return BEFORE the EV::MariaDB has answered.
# The defining async property: the Future is still pending at the moment
# the call returned. EV::run is what drives it to completion.
#
# Determinism note: the SELECT is wrapped in `AND SLEEP(0.05) = 0` so the
# server-side round-trip is forced to ~50ms. EV::MariaDB's pipelining can
# otherwise fire callbacks synchronously when the conn is hot (a previously
# released pool conn's TCP buffers still hold a queued response), making
# the Future resolve before the caller observes its return value. 50ms is
# long enough that the response cannot be in the kernel buffer at the
# moment the SQL hits the wire — the callback MUST be dispatched via EV::run.
# =============================================================================

subtest 'non-blocking: facade call returns before DB answers' => sub {
  # Issue the facade query. Do NOT pump EV::run yet.
  my $f = $storage->select_async(
    $TABLE,
    '*',
    { -and => [
        { label => 'row-7' },
        \"SLEEP(0.05) = 0",
      ]
    },
  );

  isa_ok $f, 'Future', 'select_async returns a Future';

  # THIS is the assertion that defines async-ness. If the call blocked
  # waiting for the DB, $f->is_ready would already be true here.
  ok !$f->is_ready,
    'Future is PENDING the instant select_async returns '
    . '(proves the call did not block on the DB)';

  # Now drive the event loop until it settles. Timeout bumped from 500 to
  # 5000 to give the SLEEP-injected query headroom under load.
  pump_until(sub { $f->is_ready }, 5000);

  ok $f->is_ready, 'Future resolves after EV::run drives the EV::MariaDB callback';
  ok !$f->is_failed, 'Future succeeded (no query error)';

  my @rows = $f->get;
  is scalar(@rows), 1, 'exactly one row matches label=row-7';
  is $rows[0][1], 'row-7', 'row label matches the WHERE clause';
  is $rows[0][2], 70,     'row value matches what was inserted (7 * 10)';
};

# =============================================================================
# BLOCK 2 — CONCURRENCY PROOF
# N facade calls issued in a tight loop are ALL pending simultaneously.
# No event loop has run between the calls — only after the loop.
# Each Future resolves with its own correct result, regardless of order.
#
# Determinism note: every SELECT here carries AND SLEEP(0.05) = 0 so the
# server-side round-trip is forced to ~50ms (see Block 1 for rationale).
# Without it, EV::MariaDB's pipelining on a hot pool conn can resolve some
# of these 16 Futures synchronously, intermittently failing the
# "all 16 PENDING before any EV::run" assertion.
# =============================================================================

subtest 'concurrency: N facade queries are all in-flight before any EV::run' => sub {
  my $N = 16;
  my @futures;

  # Tight loop — no EV::run in here. Each select also pulls
  # CONNECTION_ID() AS cid from the server so we can prove below that the
  # 16 in-flight queries landed on 16 DISTINCT backend connections — not
  # one hot one (which is what an LIFO pool acquire does: it reuses the
  # most-recently-released conn every time, so all 16 facade calls hit
  # the same backend CONNECTION_ID). With a FIFO pool the CIDs fan out
  # 1-per-pool-slot.
  for my $i (1 .. $N) {
    push @futures, $storage->select_async(
      $TABLE,
      # CONNECTION_ID() is a literal SQL expr (scalarref -- a plain string
      # would be backtick-quoted into an unknown column); the star must be
      # table-qualified ($TABLE.*), since a bare `*` after a named select-expr
      # is a syntax error on MySQL/MariaDB.
      [ \'CONNECTION_ID() AS cid', "$TABLE.*" ],
      { -and => [
          { label => "row-$i" },
          \"SLEEP(0.05) = 0",
        ]
      },
    );
  }

  ok scalar(@futures) == $N, "issued $N facade select_async calls";

  # EVERY Future must be pending right now. If the driver accidentally
  # serialized or blocked, some/all would already be ready.
  my @pending = grep { !$_->is_ready } @futures;
  is scalar(@pending), $N,
    "all $N Futures are PENDING before any EV::run "
    . '(proves the facade does not serialize via blocking)';

  # Drive EV::run until ALL are ready. Timeout bumped to 5000: with
  # 50ms SLEEP on each conn, 16 in-flight on 16 pool conns should drain
  # in roughly 50ms — give 100x headroom for pool contention or future
  # refactors that serialize any of the acquires.
  pump_until(sub { !grep { !$_->is_ready } @futures }, 5000);

  ok !(grep { !$_->is_ready } @futures),
    'all N Futures resolved after a single EV::run drain';

  # Each future resolves to its own row — distinct WHERE values, distinct
  # expected values. This proves completion order is decoupled from issue
  # order: even if the server returns them in a different order, each
  # future carries the row that matches ITS own WHERE.
  my %seen_cid;
  for my $i (1 .. $N) {
    my $f = $futures[$i - 1];
    ok $f->is_ready && !$f->is_failed,
      "future $i (row-$i) settled successfully";
    my @rows = $f->get;
    is scalar(@rows), 1, "future $i returned exactly one row";
    is $rows[0][2], "row-$i", "future $i got the row matching its own WHERE";
    is $rows[0][3], $i * 10, "future $i got the correct value ($i * 10)";
    # Column 0 is `cid` (CONNECTION_ID()), column 1 is the auto-increment `id`,
    # column 2 is `label`, column 3 is `value`.
    $seen_cid{ $rows[0][0] }++;
  }

  # The whole point of the FIFO pool fix (karr #13): each acquire hands
  # out a distinct idle conn, so each backend hit carries its own
  # CONNECTION_ID. Pre-fix this would collapse to 1 distinct CID even
  # with 16 in-flight Futures (LIFO pool releases back to the same conn).
  is scalar(keys %seen_cid), $N,
    "all $N concurrent queries landed on $N DISTINCT backend connections "
    . '(proves the pool acquire is FIFO, not LIFO — '
    . 'see karr #13: each facade call hit a unique server-side CONNECTION_ID)';
};

# =============================================================================
# BLOCK 3 — TRANSACTION PINNING (BEGIN/COMMIT + visible-after-commit)
# txn_do_async pins the CRUD ops to the SAME EV::MariaDB handle that ran
# BEGIN and will run COMMIT. We prove this end-to-end by:
#   (a) capturing txn_mdb at entry and confirming refaddr is stable across
#       CRUD ops (same EV::MariaDB handle),
#   (b) INSERT inside the txn,
#   (c) SELECT inside the txn sees the inserted row,
#   (d) COMMIT, then a fresh facade SELECT (different conn from the pool)
#       also sees the row.
# Then a ROLLBACK variant: insert inside a failing txn, then the row must
# NOT be visible from a fresh facade SELECT.
# =============================================================================

subtest 'txn pinning: BEGIN/COMMIT/INSERT/SELECT run on the same pinned conn' => sub {
  my $label = 'txn-commit-row';
  my $value = 4242;

  my $outer_addr;
  my $crud_addr;
  my $inside_rows;

  my $f = $storage->txn_do_async(sub {
    my ($txn) = @_;
    $outer_addr = Scalar::Util::refaddr($txn->txn_mdb);

    my $insert_f = $txn->insert_async(
      $TABLE,
      { label => $label, value => $value },
    );

    return $insert_f->then(sub {
      return $txn->select_async(
        $TABLE,
        '*',
        { label => $label },
      );
    })->then(sub {
      my @rows = @_;
      $crud_addr = Scalar::Util::refaddr($txn->txn_mdb);
      $inside_rows = \@rows;
      return Future->done();
    });
  });

  pump_until(sub { $f->is_ready });

  ok $f->is_ready && !$f->is_failed, 'txn_do_async(COMMIT path) completed successfully'
    or diag "txn failure: " . ($f->failure // 'unknown');

  ok defined $inside_rows, 'SELECT inside txn returned rows';
  is scalar(@$inside_rows), 1, 'SELECT inside txn saw the just-inserted row';
  is $inside_rows->[0][1], $label, 'visible row label matches';
  is $inside_rows->[0][2], $value, 'visible row value matches';

  is $crud_addr, $outer_addr,
    'CRUD ops inside txn_do_async ran on the SAME pinned EV::MariaDB '
    . 'connection that BEGIN ran on (txn_mdb refaddr unchanged)';

  # Post-commit: a fresh facade select_async (acquires its own pool conn)
  # must also see the committed row.
  my $post_f = $storage->select_async(
    $TABLE,
    '*',
    { label => $label },
  );
  pump_until(sub { $post_f->is_ready });
  ok $post_f->is_ready && !$post_f->is_failed, 'post-commit SELECT from facade succeeded';
  my @post_rows = $post_f->get;
  is scalar(@post_rows), 1, 'committed row visible to a fresh facade SELECT';
  is $post_rows[0][2], $value, 'committed row carries the right value';
};

subtest 'txn pinning: ROLLBACK makes INSERT invisible from fresh SELECT' => sub {
  # NOTE: this assertion only holds when $TABLE is on a transactional
  # storage engine. The MariaDB MEMORY engine does not honor ROLLBACK
  # (BEGIN/ROLLBACK are accepted but the INSERT auto-commits regardless);
  # the CREATE TABLE earlier in the test uses ENGINE=InnoDB specifically
  # so ROLLBACK here actually undoes the INSERT. Do not change the engine
  # back to MEMORY without re-checking this assertion.
  my $label = 'txn-rollback-row';
  my $value = 9999;

  my $txn_failed = 0;
  my $crud_addr;
  my $outer_addr;

  my $f = $storage->txn_do_async(sub {
    my ($txn) = @_;
    $outer_addr = Scalar::Util::refaddr($txn->txn_mdb);

    return $txn->insert_async(
      $TABLE,
      { label => $label, value => $value },
    )->then(sub {
      $crud_addr = Scalar::Util::refaddr($txn->txn_mdb);
      die "intentional failure to trigger ROLLBACK\n";
    });
  })->catch(sub {
    my $err = shift;
    $txn_failed = 1;
    return Future->done($err);
  });

  pump_until(sub { $f->is_ready });

  ok $txn_failed, 'txn_do_async(ROLLBACK path) caught the intentional failure';

  is $crud_addr, $outer_addr,
    'CRUD op inside the failing txn still ran on the pinned conn '
    . '(refaddr matches txn_mdb at entry)';

  # Fresh facade SELECT must NOT see the rolled-back row.
  my $post_f = $storage->select_async(
    $TABLE,
    '*',
    { label => $label },
  );
  pump_until(sub { $post_f->is_ready });
  ok $post_f->is_ready && !$post_f->is_failed, 'post-rollback SELECT from facade succeeded';
  my @post_rows = $post_f->get;
  is scalar(@post_rows), 0,
    'rolled-back row is NOT visible to a fresh facade SELECT '
    . '(proves ROLLBACK actually ran on the pinned conn)';
};

# =============================================================================
# BLOCK 5 — INSERT_ASYNC HASHREF RETURN SHAPE (ADR 0031 §3)
# insert_async must resolve with the returned-columns HASHREF -- the supplied
# insert data overlaid with the auto_increment PK (and any retrieve_on_insert
# columns). MySQL has no RETURNING clause, so the EV storage reads
# SELECT LAST_INSERT_ID() on the pinned connection and folds the result
# into the hashref via _insert_returned_columns. create_async /
# Row::insert_async consume this hashref via _store_inserted_columns.
#
# This subtest exercises the live wire end-to-end: real EV::MariaDB, real
# INSERT, real LII. With a blessed DBIO::ResultSource (a real schema class)
# the storage introspects the auto_increment column and overlays the LII
# value onto the matching key. With a bare table string (the path the
# other e2e subtests use), the hashref is just the supplied insert data
# (no LII overlay possible without column info) -- so we assert that the
# returned value IS a hashref in either case.
# =============================================================================

subtest 'insert_async resolves with the returned-columns hashref (ADR 0031 §3)' => sub {
  # Bare-table path: no source introspection possible, hashref == insert data.
  my $label = 'hashref-bare-' . int(rand(1_000_000));
  my $f = $storage->insert_async(
    $TABLE,
    { label => $label, value => 12345 },
  );
  pump_until(sub { $f->is_ready });
  ok $f->is_ready && !$f->is_failed, 'bare-table insert_async completed'
    or diag "bare insert failure: " . ($f->failure // 'unknown');
  my $returned = $f->get;
  is ref $returned, 'HASH',
    'bare-table insert_async resolves with a HASHREF (not the raw LII row)';
  is $returned->{label}, $label,
    'hashref carries the supplied label';
  is $returned->{value}, 12345,
    'hashref carries the supplied value';

  # Blessed-source path: introspect an is_auto_increment column, overlay LII.
  # We don't register a full schema — a tiny mock source that mimics the
  # three accessor methods the EV storage's _insert_returned_columns
  # actually calls (->name, ->columns, ->columns_info, ->primary_columns)
  # is enough to prove the LII-overlay path on the live wire. The real
  # schema/row class integration is covered by the t/resultset/async tests
  # in core (which drive create_async / Row::insert_async end-to-end).
  {
    package _HashrefTestSource;
    sub new { my $class = shift; bless { @_ }, $class }
    sub name        { $_[0]->{name} }
    sub columns     { qw(id label value) }
    sub columns_info {
      return {
        id    => { is_auto_increment => 1, is_nullable => 0 },
        label => { is_auto_increment => 0, is_nullable => 0 },
        value => { is_auto_increment => 0, is_nullable => 0 },
      };
    }
    sub primary_columns { qw(id) }
  }
  my $label2 = 'hashref-source-' . int(rand(1_000_000));
  my $source = _HashrefTestSource->new(name => $TABLE);

  my $f2 = $storage->insert_async(
    $source,
    { label => $label2, value => 67890 },
  );
  pump_until(sub { $f2->is_ready });
  ok $f2->is_ready && !$f2->is_failed, 'blessed-source insert_async completed'
    or diag "source insert failure: " . ($f2->failure // 'unknown');
  my $returned2 = $f2->get;
  is ref $returned2, 'HASH',
    'blessed-source insert_async resolves with a HASHREF';
  is $returned2->{label}, $label2, 'hashref carries the supplied label';
  is $returned2->{value}, 67890, 'hashref carries the supplied value';
  ok exists $returned2->{id},
    'hashref carries the auto_increment id (LII overlaid onto the is_auto_increment column)';
  ok defined $returned2->{id} && $returned2->{id} =~ /^\d+$/,
    'auto_increment id has a defined integer value from LAST_INSERT_ID()';
};

# --- Cleanup ----------------------------------------------------------------

# Drop the test table on a fresh facade call so reruns of this test don't
# leave it lying around in the user's database.
{
  my $f = $storage->txn_do_async(sub {
    my ($txn) = @_;
    return $txn->_query_async("DROP TABLE IF EXISTS $TABLE", []);
  });
  pump_until(sub { $f->is_ready });
  ok $f->is_ready && !$f->is_failed, "dropped $TABLE"
    or diag "drop failure: " . ($f->failure // 'unknown');
}

$storage->disconnect;
done_testing;
