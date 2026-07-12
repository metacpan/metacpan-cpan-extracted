use strict;
use warnings;
use Test::More;

# LIVE future_io roundtrip against a real PostgreSQL (dbio-postgresql karr #25).
#
# The first REAL future_io transport: connect(..., { async => 'future_io' })
# resolves DBIO::PostgreSQL::Storage::Async by convention, and drives genuinely
# non-blocking SELECT / INSERT / txn over DBD::Pg's pg_async binding through
# Future::IO (loop provided by Future::IO::Impl::IOAsync + IO::Async).
#
# Gated exactly like the other live tests (t/10-pg.t): needs DBIO_TEST_PG_*.
# Run under a live pod with:
#   DBIO_TEST_KUBECONFIG=~/.kube/config xbin/dbio-pg-k8s prove -lv t/37-future-io-live.t

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
use DBIO::Test;

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, which
# is only a recommends -- a minimal install may lack it. Load the adapter (which
# pulls the base) defensively so this live test skips cleanly rather than dying
# when dbio-async is absent. A runtime require (after the DB gate above), not a
# compile-time use, so a no-DB run still skips with the DSN message first.
eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

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
