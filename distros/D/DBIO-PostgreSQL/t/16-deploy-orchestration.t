use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

BEGIN {
  eval { require Moo; 1 }
    or plan skip_all => 'Moo not installed';
}

use DBI;
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Introspect;

# -----------------------------------------------------------------------
# v1 schema: one table with three columns
#
# All tables live in their own dedicated PG namespace so Deploy->diff
# only sees this test's tables, not residual artefacts from other tests
# in the same database.
# -----------------------------------------------------------------------
my $NS = 'dbio_deploy_test';

{
  package DeployTest::SchemaV1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('dbio_deploy_test');
  __PACKAGE__->pg_search_path('dbio_deploy_test', 'public');
}
{
  package DeployTest::SchemaV1::Result::Widget;
  use DBIO::Moo;
  use DBIO::Cake;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');

  __PACKAGE__->table('dbio_deploy_test.dbio_deploy_widget');

  col id    => serial;
  col name  => varchar(100);
  col qty   => integer;

  primary_key 'id';
}
DeployTest::SchemaV1->register_class(Widget => 'DeployTest::SchemaV1::Result::Widget');

# -----------------------------------------------------------------------
# v2 schema: same table + extra nullable column
#
# NOTE: We deliberately do NOT add a brand-new table here, because
# Diff::Table currently emits an empty CREATE TABLE shell and relies on
# Diff::Column to populate it -- which doesn't work for serial columns
# (the implicit sequence isn't created). That is a known gap to fix in
# the diff engine; this test focuses on what currently works reliably.
# -----------------------------------------------------------------------
{
  package DeployTest::SchemaV2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('dbio_deploy_test');
  __PACKAGE__->pg_search_path('dbio_deploy_test', 'public');
}
{
  package DeployTest::SchemaV2::Result::Widget;
  use DBIO::Moo;
  use DBIO::Cake;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');

  __PACKAGE__->table('dbio_deploy_test.dbio_deploy_widget');

  col id          => serial;
  col name        => varchar(100);
  col qty         => integer;
  col description => varchar(255), null;   # NEW (nullable so it can be added to a populated table)

  primary_key 'id';
}
DeployTest::SchemaV2->register_class(Widget => 'DeployTest::SchemaV2::Result::Widget');

# -----------------------------------------------------------------------
# Cleanup helper
# -----------------------------------------------------------------------
sub cleanup {
  my $h = DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0 });
  $h->do("DROP SCHEMA IF EXISTS $NS CASCADE");
  $h->do("CREATE SCHEMA $NS");
  $h->disconnect;
}

cleanup();
END {
  return unless $dsn;
  my $h = DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0 });
  $h->do("DROP SCHEMA IF EXISTS $NS CASCADE") if $h;
}

# -----------------------------------------------------------------------
# Deploy->install on a fresh database
# -----------------------------------------------------------------------
my @connect = ($dsn, $user, $pass, {
  on_connect_do => ["SET search_path TO $NS, public"],
});

my $schema_v1 = DeployTest::SchemaV1->connect(@connect);
$schema_v1->storage->dbh->do("SET search_path TO $NS, public");
my $deploy_v1 = DBIO::PostgreSQL::Deploy->new(schema => $schema_v1);

isa_ok($deploy_v1, 'DBIO::PostgreSQL::Deploy');
is($deploy_v1->schema, $schema_v1, 'schema attr returns the schema');
like($deploy_v1->temp_db_prefix, qr/^_dbio_tmp_/, 'default temp_db_prefix');

lives_ok { $deploy_v1->install } 'install lives on empty database';

# Verify the table exists
my $dbh = $schema_v1->storage->dbh;
my ($exists) = $dbh->selectrow_array(
  q{SELECT 1 FROM information_schema.tables
    WHERE table_schema = ? AND table_name = 'dbio_deploy_widget'},
  undef, $NS,
);
ok($exists, 'widget table exists after install');

# CRUD round-trip to make sure the schema is actually usable
my $widget = $schema_v1->resultset('Widget')->create({
  name => 'Sprocket', qty => 7,
});
ok($widget->id, 'auto-increment id assigned');
is($widget->name, 'Sprocket', 'name stored');
is($widget->qty, 7, 'qty stored');

# -----------------------------------------------------------------------
# Deploy->diff with no changes
# -----------------------------------------------------------------------
subtest 'diff with no changes is empty' => sub {
  my $diff = $deploy_v1->diff;
  ok($diff, 'diff object returned');
  ok(!$diff->has_changes, 'no changes detected when schema matches DB');
};

# -----------------------------------------------------------------------
# Deploy->diff after schema change
# -----------------------------------------------------------------------
my $schema_v2 = DeployTest::SchemaV2->connect(@connect);
$schema_v2->storage->dbh->do("SET search_path TO $NS, public");
my $deploy_v2 = DBIO::PostgreSQL::Deploy->new(schema => $schema_v2);

subtest 'diff detects new column' => sub {
  my $diff = $deploy_v2->diff;
  ok($diff, 'diff object returned');
  ok($diff->has_changes, 'has_changes is true');

  my $sql = $diff->as_sql;
  like($sql, qr/dbio_deploy_widget.*ADD COLUMN.*description/is,
    'diff includes new column on existing table');

  my $summary = $diff->summary;
  like($summary, qr/description/, 'summary mentions new column');
};

# -----------------------------------------------------------------------
# Deploy->apply
# -----------------------------------------------------------------------
subtest 'apply executes the diff SQL' => sub {
  my $diff = $deploy_v2->diff;
  lives_ok { $deploy_v2->apply($diff) } 'apply lives';

  my $h = $schema_v2->storage->dbh;
  my ($desc_exists) = $h->selectrow_array(
    q{SELECT 1 FROM information_schema.columns
      WHERE table_schema = ?
        AND table_name   = 'dbio_deploy_widget'
        AND column_name  = 'description'},
    undef, $NS,
  );
  ok($desc_exists, 'description column added by apply');

  # The new column should be usable
  my $w = $schema_v2->resultset('Widget')->create({
    name => 'Gear', qty => 3, description => 'A round gear',
  });
  is($w->description, 'A round gear', 'new column round-trips');
};

# -----------------------------------------------------------------------
# After apply, diff should be empty again
# -----------------------------------------------------------------------
subtest 'diff is empty after apply' => sub {
  my $diff = $deploy_v2->diff;
  ok(!$diff->has_changes, 'no further changes after apply');
};

# -----------------------------------------------------------------------
# Deploy->apply with empty diff is a no-op
# -----------------------------------------------------------------------
subtest 'apply is a no-op when diff is empty' => sub {
  my $diff = $deploy_v2->diff;
  is($deploy_v2->apply($diff), undef, 'apply returns undef on empty diff');
};

# -----------------------------------------------------------------------
# Deploy->upgrade (one-step convenience)
# -----------------------------------------------------------------------
subtest 'upgrade is a no-op when nothing to do' => sub {
  is($deploy_v2->upgrade, undef, 'upgrade returns undef when DB is up to date');
};

# Reset to v1 state to test upgrade with actual changes
cleanup();
$schema_v1 = DeployTest::SchemaV1->connect(@connect);
$deploy_v1 = DBIO::PostgreSQL::Deploy->new(schema => $schema_v1);
$deploy_v1->install;

subtest 'upgrade applies pending changes' => sub {
  # Reconnect v2 to get a fresh dbh — install above committed via v1
  my $sv2 = DeployTest::SchemaV2->connect(@connect);
  my $dv2 = DBIO::PostgreSQL::Deploy->new(schema => $sv2);

  my $diff = $dv2->upgrade;
  ok($diff, 'upgrade returns diff object when changes were applied');
  ok($diff->has_changes, 'returned diff has_changes');

  # Verify final state -- description column now exists
  my $h = $sv2->storage->dbh;
  my ($exists) = $h->selectrow_array(
    q{SELECT 1 FROM information_schema.columns
      WHERE table_schema = ?
        AND table_name   = 'dbio_deploy_widget'
        AND column_name  = 'description'},
    undef, $NS,
  );
  ok($exists, 'description column exists after upgrade');
};

# -----------------------------------------------------------------------
# Deploy->install_schema (CREATE SCHEMA IF NOT EXISTS)
# -----------------------------------------------------------------------
subtest 'install_schema creates a namespace' => sub {
  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => $schema_v1);
  my $ns = 'dbio_deploy_test_ns';

  # Cleanup
  $schema_v1->storage->dbh->do("DROP SCHEMA IF EXISTS $ns CASCADE");

  lives_ok { $deploy->install_schema($ns) } 'install_schema lives';

  my ($exists) = $schema_v1->storage->dbh->selectrow_array(
    'SELECT 1 FROM pg_namespace WHERE nspname = ?', undef, $ns,
  );
  ok($exists, 'namespace created');

  # Idempotent (CREATE SCHEMA IF NOT EXISTS)
  lives_ok { $deploy->install_schema($ns) } 'install_schema is idempotent';

  $schema_v1->storage->dbh->do("DROP SCHEMA IF EXISTS $ns CASCADE");
};

# -----------------------------------------------------------------------
# temp_db_prefix can be customised
# -----------------------------------------------------------------------
{
  my $custom = DBIO::PostgreSQL::Deploy->new(
    schema         => $schema_v1,
    temp_db_prefix => 'my_test_tmp_',
  );
  is($custom->temp_db_prefix, 'my_test_tmp_', 'temp_db_prefix is settable');
}

done_testing;
