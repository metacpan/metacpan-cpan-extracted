use strict;
use warnings;
use Test::More;

# karr #7 (ADR 0036) -- the AGE extension driver sits on the PostgreSQL base,
# and the base's atomic upsert capability has to survive the layering. This is a
# SMOKE test on purpose: it asserts that the composed AGE storage reports
# supports_upsert (a probed capability of DBIO::PostgreSQL::Storage) and that a
# plain, option-free upsert round-trips against a real server. The full upsert
# surface -- conflict targets, update sets, update_where, result shapes -- is
# covered in dbio-postgresql's own suite (t/42-upsert-live.t); nothing here
# re-tests the base.
#
# Live-only: supports_upsert is probed from the connected server, so this test
# needs a real PostgreSQL with the AGE extension, like t/10-age-live.t.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

eval { require DBIO::PostgreSQL::Storage; 1 }
  or plan skip_all => 'DBIO::PostgreSQL not installed';

# Probe the cluster for the AGE extension before doing anything else.
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# A server that is not there fails the file, with a plan (karr k113).
my $probe = LiveServer->control_dbh;

my ($age_available) = $probe->selectrow_array(
  q{SELECT 1 FROM pg_available_extensions WHERE name = 'age'}
);
$probe->disconnect;
plan skip_all => 'Apache AGE extension not available in this PostgreSQL'
  unless $age_available;

use_ok('DBIO::PostgreSQL::Age');
use_ok('DBIO::PostgreSQL::Age::Storage');

# Set up a minimal schema using the Age component, and a single plain result
# source to upsert into.
{
  package TestAgeUpsertSchema;
  use DBIO 'Schema', -pg;   # the schema declares its driver (core ADR 0067)
  __PACKAGE__->load_components('PostgreSQL::Age');
}

{
  package TestAgeUpsert::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_age_upsert_test');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    name  => { data_type => 'varchar', size => 100 },
    score => { data_type => 'integer', default_value => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

my $schema = TestAgeUpsertSchema->connect(
  $dsn, $user, $pass,
  {
    AutoCommit      => 1,
    RaiseError      => 1,
    PrintError      => 0,
    on_connect_call => 'load_age',
  },
);

# The schema declares PostgreSQL (core ADR 0067); driver determination is
# still LAZY and adapts the declared driver to its access path on the first dbh
# access (karr #8). Force the connection first.
$schema->storage->ensure_connected;

isa_ok($schema->storage, 'DBIO::PostgreSQL::Age::Storage', 'storage class');
isa_ok($schema->storage, 'DBIO::PostgreSQL::Storage', 'inherits from PostgreSQL::Storage');

# Make sure the extension is created in the test database.
$schema->storage->dbh->do('CREATE EXTENSION IF NOT EXISTS age');

$schema->register_class('Item', 'TestAgeUpsert::Item');

my $dbh = $schema->storage->dbh;
$dbh->do('DROP TABLE IF EXISTS dbio_age_upsert_test');
$dbh->do(q{
  CREATE TABLE dbio_age_upsert_test (
    id    serial       NOT NULL,
    name  varchar(100) NOT NULL,
    score integer      NOT NULL DEFAULT 0,
    CONSTRAINT dbio_age_upsert_test_pkey PRIMARY KEY (id)
  )
}, { RaiseError => 1 });

END {
  return unless $dbh;
  eval { $dbh->do('DROP TABLE IF EXISTS dbio_age_upsert_test') };
}

# --- the point of the smoke test: the extension layer must not swallow the
# --- base's probed capability.
plan skip_all => 'PostgreSQL 9.5 or newer required for INSERT ... ON CONFLICT'
  unless $schema->storage->_server_info->{normalized_dbms_version} >= 9.005;

ok $schema->storage->_use_supports_upsert,
  'the composed AGE storage declares supports_upsert (inherited from the Pg base)';

my $rs = $schema->resultset('Item');

# --- a plain, option-free upsert round-trips: the same call inserts, then
# --- updates the same row (primary key is the implicit conflict target).
my $inserted = $rs->upsert({ id => 1, name => 'alpha', score => 1 });

ok $inserted, 'plain upsert on an empty table returns a row';
is $inserted->id, 1, '... the row we asked for';
is $inserted->score, 1, '... with the inserted values';
is $rs->count, 1, '... exactly one row exists';

my $updated = $rs->upsert({ id => 1, name => 'alpha', score => 2 });

is $updated->id, 1, 'the second plain upsert wrote the SAME row -- update, not insert';
is $rs->count, 1, '... no second row appeared';
is $rs->find(1)->score, 2, '... and the attempted value was written (ON CONFLICT DO UPDATE)';

done_testing;
