use strict;
use warnings;
use Test::More;

# t/48-ddl-qualified-name-live.t -- what only a server can answer about a
# source named database.table (karr k43; offline counterpart
# t/48-ddl-qualified-name.t):
#
#   1. CREATE TABLE `db`.`t` is accepted over the MySQL wire, the table lands
#      in that database and not in the connected one, and a second diff is
#      empty (the diff reads the connected database alone).
#   2. A database the server lacks ends the install before its first
#      statement, naming table and database; no database is created.
#
# The database of the first claim is this file's own (dbio_qual_<pid>): the
# file creates it and drops it, and touches no other. The shared database
# `other` of the conformance case is never created or dropped here.

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
sub mk_schema {
  my (%tables) = @_;
  my $ns = 'DBIO::ClickHouse::Test::Qualified' . ++$ns_count;
  for my $name (sort keys %tables) {
    my $pkg = "${ns}::Result::$name";
    eval qq{package $pkg; use base 'DBIO::Core'; 1} or die $@;
    $pkg->load_components('ClickHouse::Result');
    $pkg->table($tables{$name});
    $pkg->add_columns(id => { data_type => 'integer' });
    $pkg->set_primary_key('id');
  }
  eval qq{package $ns; use base 'DBIO::Schema'; 1} or die $@;
  $ns->load_components('ClickHouse');
  $ns->register_class($_, "${ns}::Result::$_") for sort keys %tables;
  return $ns->connect(DBIO::ClickHouse::Test->test_connect_info);
}
sub tables_in {
  my ($database) = @_;
  return join ',', map { $_->[0] } @{ $dbh->selectall_arrayref(
    'SELECT name FROM system.tables WHERE database = ? ORDER BY name', undef, $database) };
}
sub database_exists {
  my ($name) = @_;
  return scalar $dbh->selectrow_array('SELECT count() FROM system.databases WHERE name = ?', undef, $name);
}

# --- 1. made in that database -------------------------------------------------
my $schema = mk_schema(Q => "$own.t", Plain => 'qual_plain');
DBIO::ClickHouse::Deploy->new(schema => $schema)->install;
is tables_in($own), 't', 'the table is made in the database its name gives';
is $dbh->selectrow_array('SELECT count() FROM system.tables WHERE database = currentDatabase() AND name = ?',
  undef, "$own.t"), 0, '... and not as a table literally named with a dot in the connected one';
is $dbh->selectrow_array('SELECT count() FROM system.tables WHERE database = currentDatabase() AND name = ?',
  undef, 'qual_plain'), 1, 'the plain table is in the connected database';
ok !DBIO::ClickHouse::Deploy->new(schema => $schema)->diff->has_changes,
  'a diff against the same declaration is empty';

# the query reaches it
$schema->resultset('Q')->create({ id => 7 });
is $schema->resultset('Q')->count, 1, 'a query through the SQLMaker reaches `db`.`t`';

# --- 2. a database the server lacks ------------------------------------------
ok !database_exists($missing), 'the database the next schema names does not exist';
my $lacking = mk_schema(Q => "$missing.t", After => 'qual_after');
my $err = do { local $@; eval { DBIO::ClickHouse::Deploy->new(schema => $lacking)->install; 1 } ? '' : "$@" };
like $err, qr/refus.*\Q$missing.t\E.*\Q$missing\E/is, 'install refuses, naming table and database';
is $dbh->selectrow_array('SELECT count() FROM system.tables WHERE database = currentDatabase() AND name = ?',
  undef, 'qual_after'), 0, '... before its first statement: the other table was not made';
ok !database_exists($missing), '... and the driver created no database';

done_testing;
