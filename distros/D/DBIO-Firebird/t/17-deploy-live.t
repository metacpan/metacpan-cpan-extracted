use strict;
use warnings;
use Test::More;

# Live temp-database roundtrip test for the DBIO::Firebird::Deploy seams that
# karr #12 fixed. These three steps cannot be exercised offline -- they hit
# real database-level DDL that DSQL cannot prepare, so a unit test with a mock
# handle would not catch the regression:
#
#   _create_temp_db  -> DBD::Firebird->create_database (NOT do("CREATE DATABASE"))
#   connect          -> _temp_connect_info / _temp_dsn (dbi:Firebird:dbname=$id)
#   _drop_temp_db    -> $temp_dbh->func("ib_drop_database") (NOT do("DROP DATABASE"))
#
# Skipped unless a DSN is provided (mirrors t/15-introspect-live.t):
#
#   DBIO_TEST_FIREBIRD_DSN  e.g. dbi:Firebird:dbname=localhost/3050:/path/test.fdb
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run live deploy tests'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Test;
use DBIO::Firebird::Deploy;

my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, {
  quote_names => 1,
}) or plan skip_all => "Cannot connect: $DBI::errstr";

# Confirm the connection actually works before asserting anything.
eval { $schema->storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);
my $dbh    = $schema->storage->dbh;

# --- exercise the #12 seams directly -----------------------------------------
# A full $deploy->diff over the whole Test::Schema can trip on unrelated
# DDL-generation gaps; this test is about the create/connect/drop seams, so we
# drive those three directly and assert the temp database really comes and goes.

my $id;
lives_ok_local(sub { $id = $deploy->_create_temp_db($dbh) },
  '_create_temp_db (DBD::Firebird->create_database) succeeds');

ok(defined $id && length $id, "temp-db identifier returned ($id)");
like($id, qr/\.fdb$/, 'temp-db identifier ends in .fdb');

# Connect to the freshly created temp db via the same connect-info path the
# orchestration uses, and prove it is a usable, separate database.
my ($tdsn, $tuser, $tpass) = $deploy->_temp_connect_info($id);
is($tdsn, "dbi:Firebird:dbname=$id",
  '_temp_dsn yields dbi:Firebird:dbname=<full id>');

my $temp_dbh = DBI->connect($tdsn, $tuser, $tpass, {
  RaiseError => 1, AutoCommit => 1, PrintError => 0, ib_dialect => 3,
});
ok($temp_dbh, 'connected to the temp database')
  or diag $DBI::errstr;

SKIP: {
  skip 'no temp connection', 2 unless $temp_dbh;

  lives_ok_local(
    sub { $temp_dbh->do('CREATE TABLE t17 (id INTEGER NOT NULL PRIMARY KEY)') },
    'can CREATE TABLE in the temp database');

  # It must be a *distinct* database, not the live one: t17 should not exist
  # back on the live handle.
  my $on_live = eval {
    $dbh->selectrow_array(
      q{SELECT 1 FROM rdb$relations WHERE rdb$relation_name = 'T17'});
  };
  ok(!$on_live, 'temp table does not appear in the live database (separate db)');

  $temp_dbh->disconnect;
}

# --- drop and confirm the file is gone ---------------------------------------
lives_ok_local(sub { $deploy->_drop_temp_db($dbh, $id) },
  '_drop_temp_db (func ib_drop_database) succeeds');

# After the drop, connecting to the temp db must fail -- it no longer exists.
{
  my $gone_dbh = DBI->connect($tdsn, $tuser, $tpass, {
    RaiseError => 0, PrintError => 0, AutoCommit => 1,
  });
  ok(!$gone_dbh, 'temp database is gone after drop (cannot reconnect)');
  $gone_dbh->disconnect if $gone_dbh;    # safety: clean up if it leaked
}

$schema->storage->disconnect;
done_testing;

# Test::Exception is not a guaranteed dep here; a tiny local lives_ok keeps the
# test self-contained and self-cleaning even when the seam dies.
sub lives_ok_local {
  my ($code, $desc) = @_;
  my $ok = eval { $code->(); 1 };
  ok($ok, $desc) or diag "died: $@";
  return $ok;
}
