#!/usr/bin/env perl
# t/59-qualified-source-name.t -- table('other.t') is table t of schema other
# (maintainer decision 2026-10-25, karr k49, conformance ddl-qualified-source-name;
# as dbio-postgresql k131).
#
# Before: DuckDB took the name whole and made a table literally called
# "other.t" in main. Now: CREATE SCHEMA IF NOT EXISTS "other", the table in it,
# its sequence in it, introspect and diff see it as other.t, and the diff
# creates, alters and drops it there. The scalar-ref form \'other.t' stays
# literal SQL (a virtual source, nothing created).
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

use DBIO::DuckDB::DDL;
use DBIO::DuckDB::Deploy;

{
  package QTest::Result::Q;
  use base 'DBIO::Core';
  __PACKAGE__->table('other.t');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package QTest::Result::Plain;
  use base 'DBIO::Core';
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package QTest::Result::Virtual;
  use base 'DBIO::Core';
  __PACKAGE__->table(\'other.v');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
}
{
  package QTest::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DuckDB');
  __PACKAGE__->register_class(Q => 'QTest::Result::Q');
  __PACKAGE__->register_class(Plain => 'QTest::Result::Plain');
}

my $schema = QTest::Schema->connect('dbi:DuckDB:dbname=:memory:', '', '', {
  AutoCommit => 1, RaiseError => 1, PrintError => 0,
});
my $dbh = $schema->storage->dbh;

my $ddl = DBIO::DuckDB::DDL->install_ddl($schema);
like $ddl, qr/CREATE SCHEMA IF NOT EXISTS "other";/, 'the schema is created if missing';
like $ddl, qr/CREATE TABLE "other"\."t"/, 'the table is created in it, both parts quoted';
unlike $ddl, qr/"other\.t"/, 'no table is named "other.t" whole';
like $ddl, qr/CREATE SEQUENCE IF NOT EXISTS "other"\."t_id_seq"/, 'its sequence lives there too';

$schema->deploy;

my ($n) = $dbh->selectrow_array(
  q{SELECT count(*) FROM information_schema.tables WHERE table_schema = 'other' AND table_name = 't'});
is $n, 1, 'other.t exists in schema other';
($n) = $dbh->selectrow_array(
  q{SELECT count(*) FROM information_schema.tables WHERE table_schema = 'main' AND table_name = 'other.t'});
is $n, 0, 'and no table "other.t" in main';
($n) = $dbh->selectrow_array(
  q{SELECT count(*) FROM information_schema.tables WHERE table_schema = 'main' AND table_name = 't'});
is $n, 1, 'main.t, the plain one, is its own table';

my $row = $schema->resultset('Q')->create({ name => 'x' });
ok defined $row->id, 'the sequence of the qualified table fills the key';
is $schema->resultset('Q')->find($row->id)->name, 'x', 'a row round-trips through other.t';

# introspect and diff
my $deploy = DBIO::DuckDB::Deploy->new(schema => $schema);
ok !$deploy->diff->has_changes, 'diff of the deployed schema against itself is empty'
  or diag $deploy->diff->as_sql;
my $model = $deploy->_new_introspect($dbh)->model;
ok exists $model->{tables}{'other.t'}, 'introspect reads the schema of the source: other.t';

# ALTER and DROP go to the qualified table
$dbh->do('ALTER TABLE other.t DROP COLUMN name');
my $diff = $deploy->diff;
like $diff->as_sql, qr/ALTER TABLE "other"\."t" ADD COLUMN "name"/, 'a missing column is added to other.t';
$deploy->apply($diff);
ok !$deploy->diff->has_changes, '... and the diff is empty after';

$dbh->do('DROP TABLE other.t');
like $deploy->diff->as_sql, qr/CREATE TABLE "other"\."t"/, 'a missing qualified table is created in its schema';
$deploy->apply($deploy->diff);
ok !$deploy->diff->has_changes, '... and then nothing is left';

# the scalar-ref form is literal SQL, no schema, no table
{
  package QTest::Schema2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DuckDB');
  __PACKAGE__->register_class(V => 'QTest::Result::Virtual');
}
my $s2 = QTest::Schema2->connect('dbi:DuckDB:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 });
unlike(DBIO::DuckDB::DDL->install_ddl($s2), qr/CREATE (SCHEMA|TABLE)/, "the scalar-ref form stays literal SQL: nothing created");

done_testing;
