#!/usr/bin/env perl
# t/67-diff-lossy.t -- which column type changes DuckDB carries out without
# loss (core k399, ADR 0080).
#
# apply runs a diff with an operation that may alter stored values only with
# allow_destructive => 1. DBIO::DuckDB::Diff::Column answers `lossy` through
# DBIO::Diff::Compare::column_change_lossy with the pairs of types measured on
# libduckdb 1.5.3 (ALTER ... SET DATA TYPE over the boundary values of the old
# type, read back through a cast to it). A widening keeps every value and runs
# as it is; everything else, in doubt, needs the release.
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

use DBIO::DuckDB::Deploy;
use DBIO::DuckDB::Diff::Column;

sub op {
  my ($from, $to) = @_;
  return DBIO::DuckDB::Diff::Column->new(
    action => 'alter', table_name => 't', column_name => 'c',
    old_info => { data_type => $from }, new_info => { data_type => $to },
  );
}

# --- the answer per pair ------------------------------------------------------
for my $pair (
  [ TINYINT => 'SMALLINT' ], [ TINYINT => 'HUGEINT' ], [ INTEGER => 'BIGINT' ],
  [ BIGINT => 'HUGEINT' ], [ UTINYINT => 'USMALLINT' ], [ UINTEGER => 'UBIGINT' ],
  [ UINTEGER => 'BIGINT' ], [ UBIGINT => 'HUGEINT' ], [ DATE => 'TIMESTAMP' ],
  [ 'DECIMAL(10,2)' => 'DECIMAL(18,2)' ],
) {
  ok !op(@$pair)->lossy, "$pair->[0] to $pair->[1] keeps every value";
}
for my $pair (
  [ BIGINT => 'INTEGER' ], [ INTEGER => 'VARCHAR' ], [ VARCHAR => 'INTEGER' ],
  [ UBIGINT => 'BIGINT' ], [ INTEGER => 'UINTEGER' ], [ FLOAT => 'DOUBLE' ],
  [ INTEGER => 'DOUBLE' ], [ INTEGER => 'DECIMAL(10,2)' ],
  [ TIMESTAMP => 'DATE' ], [ TIMESTAMP => 'TIMESTAMPTZ' ],
  [ 'DECIMAL(18,2)' => 'DECIMAL(10,2)' ], [ 'DECIMAL(10,2)' => 'DECIMAL(10,3)' ],
) {
  ok op(@$pair)->lossy, "$pair->[0] to $pair->[1] may alter or lose values";
}

ok !DBIO::DuckDB::Diff::Column->new(
  action => 'alter', table_name => 't', column_name => 'c',
  old_info => { data_type => 'INTEGER', not_null => 0 },
  new_info => { data_type => 'INTEGER', not_null => 1 },
)->lossy, 'a change of NOT NULL alone loses no value';

ok !DBIO::DuckDB::Diff::Column->new(
  action => 'drop', table_name => 't', column_name => 'c', old_info => { data_type => 'INTEGER' },
)->lossy, 'a drop is destructive, not lossy: the guard asks for it by its action';

# --- through apply: a widening runs, a narrowing waits for the release ---------
my $n = 0;
sub deploy_changing {
  my ($from, $to) = @_;
  my $ns = 'LossyTest' . ++$n;
  my $schema_class = "$ns\::Schema";
  eval "package $schema_class; use base 'DBIO::Schema'; 1" or die $@;
  $schema_class->load_components('DuckDB');
  my $class = "$ns\::Result::T";
  eval "package $class; use base 'DBIO::Core'; 1" or die $@;
  $class->table('t');
  $class->add_columns(
    id => { data_type => 'integer' },
    c  => { data_type => $to, is_nullable => 1 },
  );
  $class->set_primary_key('id');
  $schema_class->register_class(T => $class);
  my $schema = $schema_class->connect('dbi:DuckDB:dbname=:memory:', '', '', {
    AutoCommit => 1, RaiseError => 1, PrintError => 0,
  });
  my $dbh = $schema->storage->dbh;
  $dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY, c $from)");
  return ($schema, DBIO::DuckDB::Deploy->new(schema => $schema), $dbh);
}

{
  my ($schema, $deploy, $dbh) = deploy_changing(INTEGER => 'bigint');
  $dbh->do('INSERT INTO t VALUES (1, 2147483647)');
  lives_ok { $deploy->upgrade } 'INTEGER to BIGINT is applied without a release';
  my ($type) = $dbh->selectrow_array(
    q{SELECT data_type FROM information_schema.columns WHERE table_name = 't' AND column_name = 'c'});
  is $type, 'BIGINT', '... and the column is BIGINT now';
  is $dbh->selectrow_array('SELECT c FROM t'), 2147483647, '... with its value';
}
{
  my ($schema, $deploy, $dbh) = deploy_changing(BIGINT => 'integer');
  $dbh->do('INSERT INTO t VALUES (1, 7)');
  throws_ok { $deploy->upgrade } qr/allow_destructive/,
    'BIGINT to INTEGER is refused without the release, naming it';
  my ($type) = $dbh->selectrow_array(
    q{SELECT data_type FROM information_schema.columns WHERE table_name = 't' AND column_name = 'c'});
  is $type, 'BIGINT', '... and no statement has run';
  lives_ok { $deploy->upgrade(allow_destructive => 1) } '... released, it is applied';
  is $dbh->selectrow_array('SELECT c FROM t'), 7, '... and the value is there';
}

done_testing;
