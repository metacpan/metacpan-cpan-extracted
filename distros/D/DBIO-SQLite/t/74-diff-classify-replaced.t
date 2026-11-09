use strict;
use warnings;
use Test::More;

# karr k89.
#
# DBIO::Diff::Base->classify counts a `drop` as destructive unless the op
# answers true to `replaced`, the first half of a drop plus create of the
# same object. SQLite has no ALTER INDEX / ALTER VIEW, so a changed index or
# view is such a pair; its drop has to say so, or an upgrade that only
# redefines an index is classed destructive.

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBI;
use DBIO::SQLite::Diff;
use DBIO::SQLite::Introspect;

sub model {
  my (@ddl) = @_;
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  $dbh->do($_) for @ddl;
  return DBIO::SQLite::Introspect->new(dbh => $dbh)->model;
}

sub diff {
  my ($source, $target) = @_;
  return DBIO::SQLite::Diff->new(source => $source, target => $target);
}

my $table = 'CREATE TABLE "item" ("id" INTEGER PRIMARY KEY, "name" TEXT, "kind" TEXT)';

# --- a changed index: drop + create, counted as changing, not destructive ---
{
  my $d = diff(
    model($table, 'CREATE INDEX "idx_item" ON "item" ("name")'),
    model($table, 'CREATE INDEX "idx_item" ON "item" ("name", "kind")'),
  );
  my @drop = grep { $_->action eq 'drop' } @{ $d->operations };
  is(scalar @drop, 1, 'changed index: one drop');
  ok($drop[0]->replaced, 'the drop of a changed index is marked replaced');
  my $c = $d->classify;
  is($c->{class}, 'changing', 'changed index classifies as changing');
  is($c->{counts}{destructive}, 0, 'no destructive operation');
}

# --- an index that goes: still a plain, destructive drop ---
{
  my $d = diff(
    model($table, 'CREATE INDEX "idx_item" ON "item" ("name")'),
    model($table),
  );
  my ($drop) = grep { $_->action eq 'drop' } @{ $d->operations };
  ok(!$drop->replaced, 'the drop of a removed index is not replaced');
  is($d->classify->{class}, 'destructive', 'removed index stays destructive');
}

# --- a changed view ---
{
  my $d = diff(
    model($table, 'CREATE VIEW "v" AS SELECT "id" FROM "item"'),
    model($table, 'CREATE VIEW "v" AS SELECT "id", "name" FROM "item"'),
  );
  my @drop = grep { $_->action eq 'drop' } @{ $d->operations };
  is(scalar @drop, 1, 'changed view: one drop');
  ok($drop[0]->replaced, 'the drop of a changed view is marked replaced');
  is($d->classify->{class}, 'changing', 'changed view classifies as changing');
}

# --- a view that goes ---
{
  my $d = diff(
    model($table, 'CREATE VIEW "v" AS SELECT "id" FROM "item"'),
    model($table),
  );
  my ($drop) = grep { $_->action eq 'drop' } @{ $d->operations };
  ok(!$drop->replaced, 'the drop of a removed view is not replaced');
  is($d->classify->{class}, 'destructive', 'removed view stays destructive');
}

done_testing;
