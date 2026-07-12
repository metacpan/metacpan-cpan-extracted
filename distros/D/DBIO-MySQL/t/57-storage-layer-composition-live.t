use strict;
use warnings;
use Test::More;

# LIVE storage-layer composition roundtrip against a real MySQL / MariaDB (core
# karr #70; this dist is a reference future_io transport). End-to-end proof that:
#
#   1. a registered extension storage LAYER's async mirror composes onto the
#      MySQL future_io transport, and its async method -- issuing SQL with
#      standard '?' placeholders through the inherited _query_async -- returns
#      the correct rows (MySQL keeps '?' natively, so _transform_sql is identity
#      and shapes NOTHING; the layer never touches SQL shaping itself);
#   2. on_connect_do set on the owning sync storage is REPLAYED on the freshly
#      spawned pooled async connection (karr #68).
#
# Gated exactly like the other live tests (t/10-mysql.t, t/55): needs
# DBIO_TEST_MYSQL_*. Skips cleanly with no DB. Run under a live pod with:
#   DBIO_TEST_KUBECONFIG=~/.kube/config xbin/dbio-mysql-k8s --mariadb \
#     prove -lv t/57-storage-layer-composition-live.t

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
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
use DBIO::Storage::Composed;

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, only a
# recommends. Load the adapter defensively so this skips cleanly when absent. A
# runtime require (after the DB gate), so a no-DB run skips with the DSN message.
eval { require DBIO::MySQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# --- a synthetic extension: a plain sync storage layer + its async mirror ------
# The async mirror method issues '?' SQL through the INHERITED _query_async. It
# never calls _transform_sql itself -- shaping (identity, for MySQL) is the
# transport's job, done once inside _query_async.
{ package T::MyExt::Storage; sub my_ext_marker { 'sync-layer' } }
{
  package T::MyExt::Storage::Async;
  sub my_ext_names_async {
    my ($self, $name) = @_;
    return $self->_query_async(
      'SELECT name FROM artist WHERE name = ? ORDER BY name', [ $name ]
    );
  }
}

# --- Fixture: a fresh artist table, built synchronously -----------------------
my $setup = DBIO::Test::Schema->connect($dsn, $user, $pass, { quote_names => 1 });
$setup->storage->dbh_do(sub {
  my (undef, $dbh) = @_;
  local $dbh->{Warn} = 0;
  $dbh->do('DROP TABLE IF EXISTS artist');
  $dbh->do(<<'SQL');
CREATE TABLE artist (
    artistid  INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY
  , name      VARCHAR(100)
  , `rank`    INTEGER NOT NULL DEFAULT 13
  , charfield CHAR(10)
)
SQL
});

# --- The async connection, with on_connect_do to replay on pooled conns -------
# A session user variable (@dbio_async_marker): MySQL / MariaDB scope user
# variables to the connection. If the replay (karr #68) fires on the pooled async
# connection, a later SELECT of that variable over the same connection reads it
# back; otherwise it is NULL.
my $schema = DBIO::Test::Schema->connect(
  $dsn, $user, $pass,
  {
    async         => 'future_io',
    on_connect_do => [ q{SET @dbio_async_marker = 'replayed'} ],
  },
);
$schema->register_storage_layer('T::MyExt::Storage');

my $async = $schema->storage->async;
isa_ok $async, 'DBIO::MySQL::Storage::Async',
  'future_io resolved the real MySQL adapter by convention off a live MySQL storage';
isa_ok $async, 'DBIO::Async::Storage', '... a Future::IO transport';
isa_ok $async, 'T::MyExt::Storage::Async',
  'the extension async mirror composed onto the live future_io transport';
can_ok $async, 'my_ext_names_async';

my $source = $schema->source('Artist');

# --- fixture rows via the async transport ------------------------------------
$async->insert_async($source, { name => 'Miles Davis' })->get;
$async->insert_async($source, { name => 'John Coltrane' })->get;

# --- 1. the layer's async method: '?' SQL through _query_async ----------------
{
  my @rows = $async->my_ext_names_async('Miles Davis')->get;
  is scalar(@rows), 1,
    'the layer async method round-tripped exactly the matching row';
  is ref($rows[0]), 'ARRAY', 'each row is a raw arrayref (sync-cursor ->all shape)';
  is $rows[0][0], 'Miles Davis',
    "... the correct value -- MySQL kept the '?' placeholder verbatim (identity seam)";

  my @none = $async->my_ext_names_async('Nobody Here')->get;
  is scalar(@none), 0, 'a non-matching bind returns no rows (the bind really bound)';
}

# --- 2. on_connect_do replay visible on the pooled async connection (karr #68) -
{
  my @m = $async->_query_async(q{SELECT @dbio_async_marker}, [])->get;
  is $m[0][0], 'replayed',
    'on_connect_do replayed on the freshly-spawned pooled async connection (karr #68)';
}

# --- Cleanup -----------------------------------------------------------------
$async->disconnect;
$setup->storage->dbh_do(sub {
  my (undef, $dbh) = @_;
  local $dbh->{Warn} = 0;
  $dbh->do('DROP TABLE IF EXISTS artist');
});

done_testing;
