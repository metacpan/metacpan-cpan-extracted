use strict;
use warnings;
use Test::More;

# LIVE future_io roundtrip against a real PostgreSQL (dbio-postgresql karr k25).
#
# The first REAL future_io transport: connect(..., { async => 'future_io' })
# resolves DBIO::PostgreSQL::Storage::Async by convention, and drives genuinely
# non-blocking SELECT / INSERT / txn over DBD::Pg's pg_async binding through
# Future::IO (loop provided by Future::IO::Impl::IOAsync + IO::Async).
#
# Gated exactly like the other live tests (t/10-pg.t): needs DBIO_TEST_PG_*.
# Run against a live database with:
#   capped-test prove -lv t/37-future-io-live.t

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

# A Future::IO event-loop implementation is required to drive the non-blocking
# socket watcher. IO::Async is the recommended one (as dbio-async uses).
BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

use Future;
use Future::IO;
use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, which
# is only a recommends -- a minimal install may lack it. Load the adapter (which
# pulls the base) defensively so this live test skips cleanly rather than dying
# when dbio-async is absent. A runtime require (after the DB gate above), not a
# compile-time use, so a no-DB run still skips with the DSN message first.
eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# A server that is not there fails the file, with a plan (karr k113).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

# --- Fixture: a fresh artist table, built synchronously (no async here) ------
my $setup = DBIO::Test::Schema->connect($dsn, $user, $pass);
$setup->storage->dbh_do(sub {
  my (undef, $dbh) = @_;
  local $dbh->{Warn} = 0;
  $dbh->do('DROP TABLE IF EXISTS artist CASCADE');
  $dbh->do(<<'SQL');
CREATE TABLE artist (
    artistid  serial PRIMARY KEY
  , name      VARCHAR(100)
  , rank      INTEGER NOT NULL DEFAULT 13
  , charfield CHAR(10)
)
SQL
});

# --- The async connection ----------------------------------------------------
my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, { async => 'future_io' });

my $async = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::Storage::Async',
  'future_io resolved the real DBD::Pg adapter by convention off a live PG storage';
isa_ok $async, 'DBIO::Async::Storage', '... a Future::IO transport';

my $source = $schema->source('Artist');

# A Future's result, or a die once $LIMIT seconds have passed. For the cases
# whose transaction, when the thing they test is broken, does not fail but
# never ends (karr k94): they fail here instead of hanging the file. The limit
# does not cancel the Future -- a transaction that hangs is left as it is.
my $LIMIT = 10;
my $in_time = sub {
  my ($f) = @_;
  return Future->wait_any(
    $f->without_cancel,
    Future::IO->sleep($LIMIT)->then(sub {
      Future->fail("not finished after $LIMIT seconds -- it hangs\n");
    }),
  )->get;
};

# --- insert_async -> the returned-columns hashref (autoinc PK via RETURNING) --
{
  my $ret = $async->insert_async($source, { name => 'Miles Davis' })->get;
  is ref($ret), 'HASH', 'insert_async resolves the returned-columns hashref (ADR 0031 §3)';
  ok defined $ret->{artistid} && $ret->{artistid} =~ /^\d+$/,
    "... with the DB-populated autoinc PK via RETURNING * (artistid=@{[ $ret->{artistid} // 'undef' ]})";
  is $ret->{name}, 'Miles Davis', '... overlaid on the supplied insert data';
  is $ret->{rank}, 13, '... and the DB DEFAULT column (rank) folded back in';
}

# --- select_async -> raw row arrayrefs, and PROOF it is actually async --------
{
  # Insert a second artist so we have a couple of rows.
  $async->insert_async($source, { name => 'John Coltrane' })->get;

  my $f = $async->select_async('artist', [ 'artistid', 'name' ], {}, { order_by => 'artistid' });
  isa_ok $f, 'Future', 'select_async returns a Future';
  ok !$f->is_ready,
    'the Future is still PENDING right after the call -- the query was submitted '
    . 'non-blocking and only completes when the loop is pumped (real async)';

  my @rows = $f->get;   # ->get pumps the IO::Async loop
  is scalar(@rows), 2, 'select_async round-tripped both rows';
  is ref($rows[0]), 'ARRAY', 'each row is a raw arrayref (sync-cursor ->all shape)';
  is $rows[0][1], 'Miles Davis',  'first row column value';
  is $rows[1][1], 'John Coltrane', 'second row column value';
}

# --- select_async via an explicit raw Future ->then chain --------------------
{
  my $name = $async
    ->select_single_async('artist', [ 'name' ], { name => 'Miles Davis' })
    ->then(sub {
        my $row = shift;              # first row arrayref (or undef)
        return Future->done($row ? $row->[0] : undef);
      })
    ->get;
  is $name, 'Miles Davis', 'a raw ->then Future chain resolves through the live transport';
}

# --- txn_do_async: COMMIT path -----------------------------------------------
{
  my $ret = $async->txn_do_async(sub {
    my ($txn) = @_;
    return $txn->insert_async($source, { name => 'Committed Artist' });
  })->get;

  is ref($ret), 'HASH', 'txn_do_async resolves the inner insert returned-columns hashref';
  ok defined $ret->{artistid}, '... committed with a RETURNING autoinc PK';

  my @found = $async->select_async('artist', [ 'name' ], { name => 'Committed Artist' })->get;
  is scalar(@found), 1, 'the committed row is visible after the transaction';
}

# --- txn_do_async: ROLLBACK path (a die inside the coderef) -------------------
{
  my $f = $async->txn_do_async(sub {
    my ($txn) = @_;
    return $txn->insert_async($source, { name => 'Rolled Back Artist' })->then(sub {
      die "boom inside txn\n";
    });
  });
  my @r = eval { $f->get; 1 };
  like $@, qr/boom inside txn/, 'a die inside txn_do_async propagates as a Future failure';

  my @found = $async->select_async('artist', [ 'name' ], { name => 'Rolled Back Artist' })->get;
  is scalar(@found), 0, 'the failed transaction was rolled back -- no row persisted';
}

# --- txn_do_async: a COMMIT PostgreSQL answers with ROLLBACK (karr k86) --------
#
# A statement that fails inside the transaction aborts it on the server, and
# PostgreSQL answers the COMMIT after that with the command tag ROLLBACK, not
# with an error. Core k236 rolls back itself when a statement of the CONTEXT
# failed; a statement sent on the pinned connection past the context is out of
# its sight, and only this transport's _txn_commit_rolled_back tells. Claims:
#   a) past the context, its failure swallowed by the coderef: the transaction
#      fails with core's "COMMIT was answered with ROLLBACK", and the row the
#      context inserted before it is not there;
#   b) control: the same shape without the failing statement commits;
#   c) a context statement that fails and that nothing awaits (core k236),
#      issued while the insert before it has no answer yet (karr k94 has what
#      that takes): the transaction fails with that statement's own error --
#      core catches it before COMMIT, so the COMMIT-answered error does not
#      appear -- although the Future the coderef returned, over its insert,
#      resolved; and the row inserted before it is not there;
#   and after each, the next call on the pool runs.
SKIP: {
  skip 'the installed DBIO core predates _txn_commit_rolled_back (core k236)', 10
    unless DBIO::Storage::Async->can('_txn_commit_rolled_back');
  my $ROLLED_BACK = qr/COMMIT was answered with ROLLBACK/;
  my $count = sub {
    my ($name) = @_;
    return scalar(my @r = $async->select_async('artist', [ 'name' ], { name => $name })->get);
  };
  my $past_context = sub {
    my ($name, $fail) = @_;
    return $async->txn_do_async(sub {
      my ($txn) = @_;
      my $conn = $txn->txn_conn;
      return $txn->insert_async($source, { name => $name })->then(sub {
        return 'coderef result' unless $fail;
        return $async->_query_async_pinned($conn, 'SELECT 1/0', [])
          ->else(sub { Future->done })
          ->then(sub { 'coderef result' });
      });
    });
  };

  my @r = eval { $past_context->('k86 Past Context', 1)->get };
  my $err = $@;
  ok !@r, 'a) past the context: the transaction fails' or diag "it resolved with: @r";
  like $err, $ROLLED_BACK, "a) ... with core's COMMIT-answered error";
  is $count->('k86 Past Context'), 0, 'a) ... and the row the context inserted is not there';

  @r = eval { $past_context->('k86 Control', 0)->get };
  is $r[0], 'coderef result', 'b) control: the same shape without a failure commits'
    or diag "it failed: $@";
  is $count->('k86 Control'), 1, 'b) ... and its row is there';

  my $block;   # the Future the coderef returns: its insert, awaited
  @r = eval {
    $in_time->($async->txn_do_async(sub {
      my ($txn) = @_;
      my $inserted = $txn->insert_async($source, { name => 'k86 Unawaited' });
      $txn->insert_async($source, { name => 'k86 Null Rank', rank => undef });   # fails; nothing awaits it
      return $block = $inserted->then(sub { 'coderef result' });
    }));
  };
  $err = $@;
  ok !@r, 'c) an unawaited failed context statement: the transaction fails'
    or diag "it resolved with: @r";
  like $err, qr/null value in column "rank"/, "c) ... with the statement's own error";
  unlike $err, $ROLLED_BACK, 'c) ... caught before COMMIT, not by its answer';
  ok $block && $block->is_done,
    "c) ... and not through the coderef: the Future it returned, over its insert, resolved"
    or diag 'that Future ' . (
        !$block           ? 'was never made'
      : !$block->is_ready ? 'is still pending'
      :                     'failed: ' . $block->failure
    );
  is $count->('k86 Unawaited'), 0, 'c) ... and the row inserted before it is not there';
}

# --- A statement PostgreSQL cancels (karr k83) --------------------------------
# statement_timeout cancels a statement with SQLSTATE 57014, and DBD::Pg's
# pg_result does not die on that one: it returns 0E0 with only $dbh->state
# set. Claims:
#   d) a statement cancelled by statement_timeout fails its Future with an error
#      naming SQLSTATE 57014 (DBD::Pg drops the server's own text, so the
#      error cannot quote it); the connection is not retired, and the next
#      statement on it runs;
#   e) inside txn_do_async the cancellation fails the transaction with that
#      error -- not with core's COMMIT-answered one -- and the row inserted
#      before it is not there.
{
  my $CANCELLED = qr/SQLSTATE 57014 query_canceled/;

  my $conn = $async->pool->acquire->get;
  my $size = $async->pool->size;
  $async->_query_async_pinned($conn, q{SET statement_timeout = '100ms'}, [])->get;
  my @r = eval { $async->_query_async_pinned($conn, 'SELECT pg_sleep(1)', [])->get };
  my $err = $@;
  ok !@r, 'd) a statement cancelled by statement_timeout fails its Future'
    or diag 'it resolved with: ' . join ', ', map { $_ // 'undef' } @r;
  like $err, $CANCELLED, 'd) ... with an error naming SQLSTATE 57014';
  is_deeply [ $async->_query_async_pinned($conn, 'SELECT 1', [])->get ], [ [ 1 ] ],
    'd) ... and the same connection runs the next statement';
  $async->_query_async_pinned($conn, 'RESET statement_timeout', [])->get;
  $async->pool->release($conn);
  is $async->pool->size, $size, 'd) ... it was not retired from the pool';

  @r = eval {
    $async->txn_do_async(sub {
      my ($txn) = @_;
      my $tconn = $txn->txn_conn;
      return $txn->insert_async($source, { name => 'k83 Cancelled' })->then(sub {
        return $async->_query_async_pinned($tconn, q{SET LOCAL statement_timeout = '100ms'}, []);
      })->then(sub {
        return $async->_query_async_pinned($tconn, 'SELECT pg_sleep(1)', []);
      })->then(sub { 'coderef result' });
    })->get;
  };
  $err = $@;
  ok !@r, 'e) a cancelled statement in txn_do_async fails the transaction'
    or diag "it resolved with: @r";
  like $err, $CANCELLED, 'e) ... with the cancellation error';
  unlike $err, qr/COMMIT was answered with ROLLBACK/, 'e) ... not the COMMIT-answered one';
  is scalar(my @found = $async->select_async('artist', [ 'name' ], { name => 'k83 Cancelled' })->get),
    0, 'e) ... and the row inserted before it is not there';
}

# --- txn_do_async: two statements the block does not chain (karr k94) ---------
#
# Nothing makes a block await one context statement before it issues the next
# -- Future->needs_all over two of them is ordinary code -- and this transport
# has room for one statement per connection. Before dbio-async k33 the second
# went onto the connection while the first was in flight: DBI warned "st handle
# cleared whilst still active", the first never resolved, and the transaction
# never ended. The base now queues statements per pinned connection; t/80 pins
# how, on a fake DBD::Pg. Claim, against the server:
#   f) an insert and a select for the row it inserts, the select issued while
#      the insert has no answer yet: the transaction ends, with the block's
#      value; each statement resolves with its own result -- the insert with
#      its returned columns, the select, sent after it on the same connection,
#      with exactly that row; nothing warns; the row is there for another
#      session, so COMMIT went out; and the transaction's connection is back
#      in the pool, where the next call runs.
{
  my $NAME = 'k94 Unchained';
  my $idle = $async->pool->available;

  my (%st, @warned);
  my $f = $async->txn_do_async(sub {
    my ($txn) = @_;
    $st{insert}    = $txn->insert_async($source, { name => $NAME });
    $st{in_flight} = !$st{insert}->is_ready;
    $st{select}    = $txn->select_async('artist', [ 'artistid', 'name' ], { name => $NAME });
    return Future->needs_all($st{insert}, $st{select})
      ->then(sub { Future->done('block result') });
  });
  my @r = do {
    local $SIG{__WARN__} = sub { push @warned, @_ };
    eval { $in_time->($f) };
  };
  my $err = $@;
  my $outcome = sub {
    my ($s) = @_;
    return 'never issued' unless $s;
    return 'still pending' unless $s->is_ready;
    return $s->is_done ? [ $s->get ] : 'failed: ' . $s->failure;
  };

  ok $st{in_flight}, 'f) the select is issued while the insert has no answer yet';
  is $r[0], 'block result',
    "f) two unchained context statements: the transaction ends, with the block's value"
    or diag "it failed: $err";

  my $inserted = $outcome->($st{insert});
  my $row = ref $inserted && ref $inserted->[0] eq 'HASH' ? $inserted->[0] : {};
  is $row->{name}, $NAME, 'f) ... the insert resolves with its returned columns'
    or diag explain $inserted;
  like $row->{artistid} // 'undef', qr/^\d+$/, 'f) ... the RETURNING autoinc PK among them';
  is_deeply $outcome->($st{select}), [ [ $row->{artistid}, $NAME ] ],
    'f) ... the select, sent after it, with exactly that row';
  is_deeply \@warned, [], 'f) ... and nothing warned (no statement handle cleared in flight)';

  my ($there) = $setup->storage->dbh_do(sub {
    my (undef, $dbh) = @_;
    return $dbh->selectrow_array('SELECT count(*) FROM artist WHERE name = ?', undef, $NAME);
  });
  is $there, 1, 'f) ... the row is there for another session: COMMIT went out';
  is $async->pool->available, $idle, "f) ... the transaction's connection is back in the pool";
  is scalar(my @next = $async->select_async('artist', [ 'name' ], { name => $NAME })->get),
    1, 'f) ... and the next call on the pool runs';
}

# --- High-level ResultSet/Row async API end-to-end ---------------------------
{
  my $row = $schema->resultset('Artist')->create_async({ name => 'Thelonious Monk' })->get;
  ok defined $row->artistid,
    'high-level create_async stored the RETURNING autoinc PK back onto the Row';
  is $row->name, 'Thelonious Monk', '... and the supplied data';

  my @all = $schema->resultset('Artist')->all_async->get;
  ok scalar(@all) >= 4, 'high-level all_async inflated the result objects';
  ok +(grep { $_->name eq 'Thelonious Monk' } @all),
    '... including the async-created row';
}

# --- Cleanup -----------------------------------------------------------------
$async->disconnect;
$setup->storage->dbh_do(sub {
  my (undef, $dbh) = @_;
  local $dbh->{Warn} = 0;
  $dbh->do('DROP TABLE IF EXISTS artist CASCADE');
});

done_testing;
