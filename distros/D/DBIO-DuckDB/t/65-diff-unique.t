#!/usr/bin/env perl
# t/65-diff-unique.t -- UNIQUE in the diff model (karr k49, maintainer
# decision 2026-10-25) and the refusal of DROP COLUMN that DuckDB cannot do.
#
# A table the diff creates keeps its UNIQUE constraints. A UNIQUE on a table
# that exists is added as CREATE UNIQUE INDEX (DuckDB enforces it: measured,
# libduckdb 1.5.3, a duplicate is "Constraint Error: Duplicate key"), after a
# look at the rows -- existing duplicates are refused before the first
# statement. A UNIQUE constraint cannot be dropped from a table (no ALTER TABLE
# for it), nor a column dropped while an index or UNIQUE stands on a later one
# ("an index depends on a column after it"): the table is rebuilt (karr k50,
# t/66-diff-rebuild.t).
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

use DBIO::DuckDB::Deploy;
use DBIO::DuckDB::Introspect;

my $n = 0;
sub schema_for {
  my (%src) = @_;
  my $ns = 'UqTest' . ++$n;
  my $schema = "$ns\::Schema";
  eval "package $schema; use base 'DBIO::Schema'; 1" or die $@;
  $schema->load_components('DuckDB');
  for my $name (sort keys %src) {
    my $s = $src{$name};
    my $class = "$ns\::Result::$name";
    eval "package $class; use base 'DBIO::Core'; 1" or die $@;
    $class->table($s->{table});
    my %pk = map { $_ => 1 } @{ $s->{pk} };
    $class->add_columns(map { $_ => { data_type => 'integer', is_nullable => $pk{$_} ? 0 : 1 } } @{ $s->{columns} });
    $class->set_primary_key(@{ $s->{pk} });
    $class->add_unique_constraint(@$_) for @{ $s->{unique} || [] };
    $schema->register_class($name => $class);
  }
  return $schema->connect('dbi:DuckDB:dbname=:memory:', '', '', {
    AutoCommit => 1, RaiseError => 1, PrintError => 0,
  });
}
sub deploy_of { DBIO::DuckDB::Deploy->new(schema => $_[0]) }

# --- the model carries UNIQUE constraints ------------------------------------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'],
                                 unique => [ [ t_code => ['code'] ] ] });
  $schema->deploy;
  my $model = DBIO::DuckDB::Introspect->new(dbh => $schema->storage->dbh)->model;
  my ($uq) = values %{ $model->{unique_constraints}{t} || {} };
  is_deeply $uq && $uq->{columns}, ['code'], 'the model has the UNIQUE constraint of t';
}

# --- a table the diff creates keeps its UNIQUE -------------------------------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'],
                                 unique => [ [ t_code => ['code'] ] ] });
  my $deploy = deploy_of($schema);
  my $diff   = $deploy->diff;
  like $diff->as_sql, qr/UNIQUE \("code"\)/, 'a new table brings its UNIQUE';
  $deploy->apply($diff);
  my $dbh = $schema->storage->dbh;
  $dbh->do('INSERT INTO t VALUES (1, 5)');
  throws_ok { $dbh->do('INSERT INTO t VALUES (2, 5)') } qr/unique|duplicate/i, 'and it is enforced';
  ok !$deploy->diff->has_changes, 'diff is empty afterwards';
}

# --- a UNIQUE on a table that exists: CREATE UNIQUE INDEX ---------------------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'],
                                 unique => [ [ t_code => ['code'] ] ] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER)');
  $dbh->do('INSERT INTO t VALUES (1, 5)');
  my $deploy = deploy_of($schema);
  my $diff   = $deploy->diff;
  like $diff->as_sql, qr/CREATE UNIQUE INDEX "[^"]+" ON "t" \("code"\)/, 'added as a unique index';
  $deploy->apply($diff);
  throws_ok { $dbh->do('INSERT INTO t VALUES (2, 5)') } qr/unique|duplicate/i, 'DuckDB enforces it';
  ok !$deploy->diff->has_changes, 'the diff after is empty: the unique index satisfies the constraint';
  my $intro = DBIO::DuckDB::Introspect->new(dbh => $dbh);
  is scalar(grep { join(',', @{ $_->[1] }) eq 'code' } @{ $intro->table_uniq_info('t') }), 1,
    'and it is listed once, not as index and as constraint';
}

# --- existing duplicates: refused before the first statement -------------------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code extra)], pk => ['id'],
                                 unique => [ [ t_code => ['code'] ] ] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER)');
  $dbh->do('INSERT INTO t VALUES (1, 5), (2, 5), (3, NULL), (4, NULL)');
  my $deploy = deploy_of($schema);
  throws_ok { $deploy->upgrade } qr/refus.*t.*code.*duplicate|refus.*duplicate.*t.*code/is,
    'a UNIQUE over duplicate values is refused, naming table and column';
  my ($cols) = $dbh->selectrow_array(
    q{SELECT count(*) FROM information_schema.columns WHERE table_name = 't'});
  is $cols, 2, '... before the first statement (the new column is not there)';
}
{
  # NULLs are no duplicates
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'],
                                 unique => [ [ t_code => ['code'] ] ] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER)');
  $dbh->do('INSERT INTO t VALUES (1, NULL), (2, NULL)');
  lives_ok { deploy_of($schema)->upgrade } 'several NULLs are no duplicates';
}

# --- a UNIQUE constraint that is dropped, a column under a later one: rebuilt ---
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER, UNIQUE (code))');
  like deploy_of($schema)->diff->summary, qr/rebuild table: t.*UNIQUE \(code\)/is,
    'a UNIQUE constraint that is no longer declared rebuilds the table (t/66-diff-rebuild.t)';
}
{
  my $schema = schema_for(W => { table => 'wide', columns => [qw(id c)], pk => ['id'] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE wide (id INTEGER PRIMARY KEY, a INTEGER, b INTEGER, c INTEGER, UNIQUE (b, c))');
  like deploy_of($schema)->diff->summary, qr/rebuild table: wide.*"?a"?.*later column/is,
    'dropping a column before an indexed one rebuilds the table, the summary names the column';
}
{
  my $schema = schema_for(W => { table => 'wide', columns => [qw(id b)], pk => ['id'] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE wide (id INTEGER PRIMARY KEY, b INTEGER, c INTEGER)');
  lives_ok { deploy_of($schema)->upgrade(allow_destructive => 1) } 'dropping the last column is fine once the drop is released';
}

done_testing;
