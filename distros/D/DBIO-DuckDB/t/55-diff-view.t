#!/usr/bin/env perl
# t/55-diff-view.t -- views in the diff (karr k49, conformance diff-view-*).
#
# A view is created as a view, removed as a view and replaced when its
# definition changed. The diff used to take a view for a table: DROP TABLE for
# a view that had gone, ALTER TABLE ADD COLUMN for one that selects another
# column, nothing at all for a view that did not exist yet.
#
# Each scenario takes the live model of one in-memory database and the target
# model of another, diffs them, applies the diff to the first and diffs again.

use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

use DBI;
use DBIO::DuckDB::Introspect;
use DBIO::DuckDB::Diff;

sub mem {
  return DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
}

sub scenario {
  my ($from, $to) = @_;
  my ($live, $want) = (mem(), mem());
  $live->do($_) for @$from;
  $want->do($_) for @$to;
  my $diff = DBIO::DuckDB::Diff->new(
    source => DBIO::DuckDB::Introspect->new(dbh => $live)->model,
    target => DBIO::DuckDB::Introspect->new(dbh => $want)->model,
  );
  return ($diff, $live, $want);
}

sub settled {
  my ($diff, $live, $want) = @_;
  my $sql = eval { $diff->as_sql };
  is $@, '', 'the diff renders' or return;
  eval { $live->do($_) for grep { /\S/ } split /;\s*\n/, $sql; 1 } or diag $@;
  my $again = DBIO::DuckDB::Diff->new(
    source => DBIO::DuckDB::Introspect->new(dbh => $live)->model,
    target => DBIO::DuckDB::Introspect->new(dbh => $want)->model,
  );
  ok !$again->has_changes, 'a second diff is empty' or diag $again->as_sql;
}

my $base = 'CREATE TABLE base (id INTEGER PRIMARY KEY, name VARCHAR, extra VARCHAR)';

{
  my @r = scenario([ $base ], [ $base, 'CREATE VIEW v AS SELECT id, name FROM base' ]);
  like $r[0]->as_sql, qr/CREATE VIEW "?v"? AS/i, 'a new view is created as a view';
  unlike $r[0]->as_sql, qr/CREATE TABLE/i, '... never as a table';
  settled(@r);
  my ($kind) = $r[1]->selectrow_array(
    q{SELECT table_type FROM information_schema.tables WHERE table_name = 'v'});
  is $kind, 'VIEW', 'the live object is a view';
}

{
  my @r = scenario([ $base, 'CREATE VIEW v AS SELECT id, name FROM base' ], [ $base ]);
  like $r[0]->as_sql, qr/DROP VIEW "?v"?/i, 'a gone view is dropped as a view';
  unlike $r[0]->as_sql, qr/DROP TABLE/i, '... never as a table';
  settled(@r);
}

{
  my @r = scenario(
    [ $base, 'CREATE VIEW v AS SELECT id, name FROM base' ],
    [ $base, 'CREATE VIEW v AS SELECT id, name, extra FROM base' ],
  );
  unlike $r[0]->as_sql, qr/ALTER TABLE/i, 'a changed view is no ALTER TABLE';
  like $r[0]->as_sql, qr/DROP VIEW.*CREATE VIEW/si, 'it is dropped and created again';
  settled(@r);
}

{
  my @r = scenario(
    [ $base, 'CREATE VIEW v AS SELECT id, name FROM base' ],
    [ $base, 'CREATE VIEW v AS SELECT id, name FROM base' ],
  );
  ok !$r[0]->has_changes, 'the same view is no change';
}

{
  my @r = scenario(
    [ $base, 'CREATE VIEW v AS SELECT id, name FROM base' ],
    [ $base, 'CREATE VIEW "v" AS SELECT id, name FROM base' ],
  );
  ok !$r[0]->has_changes, 'the spelling of the view name is no change';
}

done_testing;
