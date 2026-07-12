use strict;
use warnings;
use Test::More;

# LIVE storage-layer composition roundtrip against a real PostgreSQL (core karr
# #70; this dist is the reference future_io transport). End-to-end proof that:
#
#   1. a registered extension storage LAYER's async mirror composes onto the
#      PostgreSQL future_io transport, and its async method -- issuing SQL with
#      SQL-standard '?' placeholders through the inherited _query_async -- returns
#      the correct rows (the '?' -> '$N' seam shapes ONCE inside the transport;
#      the layer never shapes SQL itself);
#   2. on_connect_do set on the owning sync storage is REPLAYED on the freshly
#      spawned pooled async connection (karr #68).
#
# Gated exactly like the other live tests (t/10-pg.t, t/37): needs DBIO_TEST_PG_*.
# Skips cleanly with no DB. Run under a live pod with:
#   DBIO_TEST_KUBECONFIG=~/.kube/config xbin/dbio-pg-k8s prove -lv t/39-storage-layer-composition-live.t

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

use DBIO::Test;
use DBIO::Storage::Composed;

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, only a
# recommends. Load the adapter defensively so this skips cleanly when absent. A
# runtime require (after the DB gate), so a no-DB run skips with the DSN message.
eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# --- a synthetic extension: a plain sync storage layer + its async mirror ------
# The async mirror method issues '?' SQL through the INHERITED _query_async. It
# never calls _transform_sql itself -- shaping is the transport's job, once.
{ package T::PGExt::Storage; sub pg_ext_marker { 'sync-layer' } }
{
  package T::PGExt::Storage::Async;
  sub pg_ext_names_async {
    my ($self, $name) = @_;
    return $self->_query_async(
      'SELECT name FROM artist WHERE name = ? ORDER BY name', [ $name ]
    );
  }
}

# --- Fixture: a fresh artist table, built synchronously -----------------------
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

# --- The async connection, with on_connect_do to replay on pooled conns -------
# A custom (dotted) session GUC: PostgreSQL accepts it session-level without a
# prior definition. If the replay (karr #68) fires on the pooled connection, a
# later current_setting() over that same connection reads it back.
my $schema = DBIO::Test::Schema->connect(
  $dsn, $user, $pass,
  {
    async         => 'future_io',
    on_connect_do => [ q{SET dbio_async.marker = 'replayed'} ],
  },
);
$schema->register_storage_layer('T::PGExt::Storage');

my $async = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::Storage::Async',
  'future_io resolved the real DBD::Pg adapter by convention off a live PG storage';
isa_ok $async, 'DBIO::Async::Storage', '... a Future::IO transport';
isa_ok $async, 'T::PGExt::Storage::Async',
  'the extension async mirror composed onto the live future_io transport';
can_ok $async, 'pg_ext_names_async';

my $source = $schema->source('Artist');

# --- fixture rows via the async transport ------------------------------------
$async->insert_async($source, { name => 'Miles Davis' })->get;
$async->insert_async($source, { name => 'John Coltrane' })->get;

# --- 1. the layer's async method: '?' SQL through _query_async ----------------
{
  my @rows = $async->pg_ext_names_async('Miles Davis')->get;
  is scalar(@rows), 1,
    'the layer async method round-tripped exactly the matching row';
  is ref($rows[0]), 'ARRAY', 'each row is a raw arrayref (sync-cursor ->all shape)';
  is $rows[0][0], 'Miles Davis',
    "... the correct value -- the '?' placeholder was shaped to \$1 once at the seam";

  my @none = $async->pg_ext_names_async('Nobody Here')->get;
  is scalar(@none), 0, 'a non-matching bind returns no rows (the bind really bound)';
}

# --- 2. on_connect_do replay visible on the pooled async connection (karr #68) -
{
  my @m = $async->_query_async(
    q{SELECT current_setting('dbio_async.marker', true)}, []
  )->get;
  is $m[0][0], 'replayed',
    'on_connect_do replayed on the freshly-spawned pooled async connection (karr #68)';
}

# --- Cleanup -----------------------------------------------------------------
$async->disconnect;
$setup->storage->dbh_do(sub {
  my (undef, $dbh) = @_;
  local $dbh->{Warn} = 0;
  $dbh->do('DROP TABLE IF EXISTS artist CASCADE');
});

done_testing;
