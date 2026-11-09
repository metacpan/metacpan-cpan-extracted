use strict;
use warnings;
use Test::More;

# t/49-ddl-qualified-view-live.t -- what only a server can answer about a view
# named database.view (karr k43; offline counterpart
# t/49-ddl-qualified-view.t):
#
#   1. CREATE VIEW `db`.`v` is accepted over the MySQL wire, the view lands in
#      that database and not in the connected one, a query reaches it, and a
#      second diff is empty (the diff reads the connected database alone).
#   2. The upgrade neither replaces nor drops it: a view of another database
#      is outside the diff, whatever the schema declares or no longer declares.
#   3. A database the server lacks ends the install before its first
#      statement, naming view and database; no database is created.
#
# The database is this file's own (dbio_qual_<pid>): created and dropped here.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::Deploy;
use DBIO::ClickHouse::DDL::Emit qw(create_database drop_database);

my $admin = DBIO::ClickHouse::Test->init_schema(no_deploy => 1);
my $dbh   = $admin->storage->dbh;

my $own     = "dbio_qual_$$";
my $missing = "dbio_qual_missing_$$";
$dbh->do(drop_database(name => $own, if_exists => 1));
$dbh->do(create_database(name => $own));
END { eval { DBI->connect($ENV{DBIO_TEST_CLICKHOUSE_DSN}, $ENV{DBIO_TEST_CLICKHOUSE_DBUSER},
  $ENV{DBIO_TEST_CLICKHOUSE_DBPASS}, { RaiseError => 1 })->do(drop_database(name => $own, if_exists => 1)) } }

my $ns_count = 0;
# %sources: name => { table, view (select, optional) }
sub mk_schema {
  my (%sources) = @_;
  my $ns = 'DBIO::ClickHouse::Test::QualView' . ++$ns_count;
  for my $name (sort keys %sources) {
    my $def = $sources{$name};
    my $pkg = "${ns}::Result::$name";
    eval qq{package $pkg; use base 'DBIO::Core'; 1} or die $@;
    $pkg->load_components('ClickHouse::Result');
    if ($def->{view}) {
      $pkg->table_class('DBIO::ResultSource::View');
      $pkg->table($def->{table});
      $pkg->result_source_instance->view_definition($def->{view});
      $pkg->result_source_instance->is_virtual(0);
    }
    else {
      $pkg->table($def->{table});
    }
    $pkg->add_columns(id => { data_type => 'integer' });
    $pkg->set_primary_key('id') unless $def->{view};
  }
  eval qq{package $ns; use base 'DBIO::Schema'; 1} or die $@;
  $ns->load_components('ClickHouse');
  $ns->register_class($_, "${ns}::Result::$_") for sort keys %sources;
  return $ns->connect(DBIO::ClickHouse::Test->test_connect_info);
}
sub engines_in {
  my ($database) = @_;
  return join ',', map { "$_->[0]:$_->[1]" } @{ $dbh->selectall_arrayref(
    'SELECT name, engine FROM system.tables WHERE database = ? ORDER BY name', undef, $database) };
}
sub in_current {
  my ($name) = @_;
  return scalar $dbh->selectrow_array(
    'SELECT count() FROM system.tables WHERE database = currentDatabase() AND name = ?', undef, $name);
}
sub database_exists {
  return scalar $dbh->selectrow_array('SELECT count() FROM system.databases WHERE name = ?', undef, $_[0]);
}

# --- 1. made in that database -------------------------------------------------
my %declared = (
  Base => { table => 'qv_base' },
  Q    => { table => "$own.v", view => 'SELECT id FROM qv_base' },
);
my $schema = mk_schema(%declared);
DBIO::ClickHouse::Deploy->new(schema => $schema)->install;
is engines_in($own), 'v:View', 'the view is made in the database its name gives';
is in_current("$own.v"), 0, '... and not as a view literally named with a dot in the connected one';
is in_current('qv_base'), 1, 'the plain table is in the connected database';
ok !DBIO::ClickHouse::Deploy->new(schema => $schema)->diff->has_changes,
  'a diff against the same declaration is empty';

$dbh->do('INSERT INTO qv_base (id) VALUES (7)');
is $schema->resultset('Q')->count, 1, 'a query through the SQLMaker reaches `db`.`v`';

# --- 2. outside the diff ------------------------------------------------------
my $changed = mk_schema(%declared, Q => { table => "$own.v", view => 'SELECT id, 1 AS one FROM qv_base' });
ok !DBIO::ClickHouse::Deploy->new(schema => $changed)->diff->has_changes,
  'a changed selection of a view in another database is not compared';
my $gone = mk_schema(Base => $declared{Base});
ok !DBIO::ClickHouse::Deploy->new(schema => $gone)->diff->has_changes,
  'a view the schema no longer declares, in another database, is not dropped';
is engines_in($own), 'v:View', '... it is still there';

# --- 3. a database the server lacks ------------------------------------------
ok !database_exists($missing), 'the database the next schema names does not exist';
my $lacking = mk_schema(Q => { table => "$missing.v", view => 'SELECT 1 AS id' },
                        After => { table => 'qv_after' });
my $err = do { local $@; eval { DBIO::ClickHouse::Deploy->new(schema => $lacking)->install; 1 } ? '' : "$@" };
like $err, qr/refus.*\Q$missing.v\E.*\Q$missing\E/is, 'install refuses, naming view and database';
is in_current('qv_after'), 0, '... before its first statement: the other table was not made';
ok !database_exists($missing), '... and the driver created no database';

done_testing;
