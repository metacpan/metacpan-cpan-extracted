#!/usr/bin/env perl
# t/56-diff-add-column.t -- ADD COLUMN with NOT NULL or a default (karr k49,
# conformance diff-column-added-*).
#
# DuckDB refuses "ADD COLUMN c T NOT NULL [DEFAULT x]" ("Adding columns with
# constraints not yet supported") and an expression default in ADD COLUMN
# ("Cannot prepare multiple statements at once"). The diff used to emit both
# and died half way. Now: ADD COLUMN with a constant default stays one
# statement; an expression default is set after the column exists and fills
# the rows that are there; NOT NULL comes last. A NOT NULL column without a
# default over rows is refused before the first statement, naming table and
# column (maintainer decision 2026-10-25), and so is a column that becomes
# NOT NULL over NULLs.

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

use DBI;
use DBIO::DuckDB::Introspect;
use DBIO::DuckDB::Diff;
use DBIO::DuckDB::Deploy;
use DBIO::DuckDB::Test;

sub model_with {
  my ($dbh, $table, %add) = @_;
  my $model = DBIO::DuckDB::Introspect->new(dbh => $dbh)->model;
  my $t = Storable::dclone($model);
  for my $c (@{ $t->{columns}{$table} }) {
    $c = { %$c, %{ $add{change}{ $c->{column_name} } } } if $add{change}{ $c->{column_name} };
  }
  push @{ $t->{columns}{$table} }, $add{column} if $add{column};
  return ($model, $t);
}
use Storable ();

my $schema = DBIO::DuckDB::Test->init_schema(no_deploy => 1);
my $dbh    = $schema->storage->dbh;
my $deploy = DBIO::DuckDB::Deploy->new(schema => $schema);
$dbh->do('CREATE TABLE note (id INTEGER PRIMARY KEY, body VARCHAR)');

sub diff_for {
  my ($table, %add) = @_;
  my ($src, $tgt) = model_with($dbh, $table, %add);
  return DBIO::DuckDB::Diff->new(source => $src, target => $tgt);
}

# expression default, NOT NULL, rows present: filled and constrained
$dbh->do(q{INSERT INTO note VALUES (1, 'one')});
my $diff = diff_for(note => column => {
  column_name => 'created', data_type => 'TIMESTAMP', not_null => 1,
  default_value => 'CURRENT_TIMESTAMP',
});
my $sql = $diff->as_sql;
unlike $sql, qr/ADD COLUMN[^;]*NOT NULL/i, 'NOT NULL is not part of ADD COLUMN';
unlike $sql, qr/ADD COLUMN[^;]*DEFAULT/i,  'an expression default is not part of ADD COLUMN';
lives_ok { $deploy->apply($diff) } 'expression default + NOT NULL applies over rows';
my ($created) = $dbh->selectrow_array('SELECT created FROM note WHERE id = 1');
like $created, qr/^\d{4}-\d\d-\d\d/, 'the row that was there has the default';
$dbh->do(q{INSERT INTO note (id, body) VALUES (2, 'two')});
($created) = $dbh->selectrow_array('SELECT created FROM note WHERE id = 2');
like $created, qr/^\d{4}-\d\d-\d\d/, 'a new row gets the default';
ok !DBIO::DuckDB::Diff->new(
  source => DBIO::DuckDB::Introspect->new(dbh => $dbh)->model,
  target => (model_with($dbh, 'note'))[1],
)->has_changes, 'the column reads back as declared';
throws_ok { $dbh->do('INSERT INTO note (id, body, created) VALUES (3, NULL, NULL)') }
  qr/NOT NULL/i, '... and is NOT NULL';

# constant default + NOT NULL
$diff = diff_for(note => column => {
  column_name => 'kind', data_type => 'VARCHAR', not_null => 1, default_value => "'a'",
});
lives_ok { $deploy->apply($diff) } 'constant default + NOT NULL applies';
is_deeply [ $dbh->selectrow_array('SELECT kind FROM note WHERE id = 1') ], ['a'],
  'the row that was there has the constant';

# NOT NULL without a default over rows: refused before the first statement
$diff = diff_for(note => column => {
  column_name => 'code', data_type => 'VARCHAR', not_null => 1,
});
throws_ok { $deploy->apply($diff) } qr/note\.code/,
  'NOT NULL without default over rows is refused, naming table and column';
is scalar(@{ DBIO::DuckDB::Introspect->new(dbh => $dbh)->model->{columns}{note} }), 4,
  '... and nothing was applied';

# the same over an empty table passes
$dbh->do('CREATE TABLE empty_t (id INTEGER PRIMARY KEY)');
$diff = diff_for(empty_t => column => {
  column_name => 'code', data_type => 'VARCHAR', not_null => 1,
});
lives_ok { $deploy->apply($diff) } 'NOT NULL without default on an empty table applies';

# NOT NULL over NULLs: refused; over no NULLs: applied
$dbh->do(q{INSERT INTO note (id, body) VALUES (4, NULL)});
$diff = diff_for(note => change => { body => { not_null => 1 } });
throws_ok { $deploy->apply($diff) } qr/note\.body/,
  'NOT NULL over NULLs is refused, naming table and column';
$dbh->do('DELETE FROM note WHERE id = 4');
$diff = diff_for(note => change => { body => { not_null => 1 } });
lives_ok { $deploy->apply($diff) } 'NOT NULL over rows without NULL applies';

done_testing;
