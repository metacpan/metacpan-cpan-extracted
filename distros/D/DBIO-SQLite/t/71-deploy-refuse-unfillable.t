use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBI;
use DBIO::SQLite::Deploy;
use DBIO::SQLite::Diff;
use DBIO::SQLite::Introspect;

# karr k91 -- what the shared Diff list (t/68) found.
#
# 1. A column the schema stops giving a default is a column without one. The
#    core leaves a field the target does not state alone, and the target here
#    is the introspection of the deployed schema, which states all of it: the
#    diff saw no change and the old default stayed.
#
# 2. A NOT NULL column without a default, added to a table that holds rows, and
#    a column that becomes NOT NULL over rows with a NULL in it are things
#    SQLite cannot do. Both came out of the server in the middle of the diff
#    (ADD COLUMN: "Cannot add a NOT NULL column with default value NULL";
#    rebuild: "NOT NULL constraint failed"). Deploy now looks at the rows before
#    the first statement and refuses, naming table and column. A table that
#    does not hold such rows is not refused.

{
  package Refuse::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}

sub memory_dbh {
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  return $dbh;
}

sub model { DBIO::SQLite::Introspect->new(dbh => $_[0])->model }

# A diff of a live database against the one the target statements make, and the
# deploy that applies it to the live one.
sub upgrade_to {
  my ($live, @target_sql) = @_;
  my $target = memory_dbh();
  $target->do($_) for @target_sql;
  my $diff = DBIO::SQLite::Diff->new(source => model($live), target => model($target));
  my $schema = Refuse::Schema->connect(sub { $live });
  return (DBIO::SQLite::Deploy->new(schema => $schema), $diff);
}

# --- 1. default removed -------------------------------------------------------
{
  my $live = memory_dbh();
  $live->do(q{CREATE TABLE "opt" ("id" INTEGER NOT NULL, "c" VARCHAR(10) DEFAULT 'x', PRIMARY KEY ("id"))});
  $live->do(q{INSERT INTO "opt" ("id") VALUES (1)});

  my ($deploy, $diff) = upgrade_to($live,
    q{CREATE TABLE "opt" ("id" INTEGER NOT NULL, "c" VARCHAR(10), PRIMARY KEY ("id"))});
  ok($diff->has_changes, 'a default the target does not give is a change');
  like($diff->summary, qr/column c: default 'x' -> none/, '... which names the default');

  $deploy->apply($diff);
  $live->do(q{INSERT INTO "opt" ("id") VALUES (2)});
  is_deeply($live->selectcol_arrayref(q{SELECT c FROM "opt" ORDER BY id}), [ 'x', undef ],
    'the row keeps its value, the next row has no default');
  ok(!model($live)->{columns}{opt}[1]{default_value}, '... and the column has none');

  # a DEFAULT NULL is no default: nothing to remove
  my $null = memory_dbh();
  $null->do(q{CREATE TABLE "opt" ("id" INTEGER NOT NULL, "c" VARCHAR(10) DEFAULT NULL, PRIMARY KEY ("id"))});
  my (undef, $same) = upgrade_to($null,
    q{CREATE TABLE "opt" ("id" INTEGER NOT NULL, "c" VARCHAR(10), PRIMARY KEY ("id"))});
  ok(!$same->has_changes, 'DEFAULT NULL against no default is no change');
}

# --- 2. refused before the server is asked -----------------------------------
{
  my $live = memory_dbh();
  $live->do(q{CREATE TABLE "base" ("id" INTEGER NOT NULL, "name" TEXT, PRIMARY KEY ("id"))});
  $live->do(q{INSERT INTO "base" ("id", "name") VALUES (1, 'one')});

  my ($deploy, $diff) = upgrade_to($live,
    q{CREATE TABLE "other" ("id" INTEGER NOT NULL, PRIMARY KEY ("id"))},
    q{CREATE TABLE "base" ("id" INTEGER NOT NULL, "name" TEXT, "code" VARCHAR(10) NOT NULL, PRIMARY KEY ("id"))});

  throws_ok { $deploy->apply($diff) }
    qr/refuses to add the column base\.code: it is NOT NULL without a default, and table base holds rows/,
    'NOT NULL column without default over rows: refused, table and column named';
  ok(!model($live)->{tables}{other}, 'nothing of the diff had run');

  $live->do(q{DELETE FROM "base"});
  lives_ok { $deploy->apply($diff) } 'the same diff on an empty table is applied';
  ok((grep { $_->{column_name} eq 'code' } @{ model($live)->{columns}{base} }),
    '... and the column is there');
}

{
  my $live = memory_dbh();
  $live->do(q{CREATE TABLE "opt" ("id" INTEGER NOT NULL, "c" VARCHAR(20), PRIMARY KEY ("id"))});
  $live->do(q{INSERT INTO "opt" ("id", "c") VALUES (1, NULL), (2, 'x')});

  my ($deploy, $diff) = upgrade_to($live,
    q{CREATE TABLE "opt" ("id" INTEGER NOT NULL, "c" VARCHAR(20) NOT NULL, PRIMARY KEY ("id"))});

  throws_ok { $deploy->apply($diff) }
    qr/refuses to make the column opt\.c NOT NULL: table opt holds rows where it is NULL/,
    'NOT NULL over a NULL: refused, table and column named';
  is($live->selectrow_array(q{SELECT count(*) FROM "opt"}), 2, 'the rows are as they were');

  $live->do(q{UPDATE "opt" SET c = 'filled' WHERE c IS NULL});
  lives_ok { $deploy->apply($diff) } 'without the NULL the rebuild is applied';
  is($live->selectrow_array(q{SELECT count(*) FROM "opt"}), 2, '... and keeps the rows');
}

{
  # a rebuild for another reason, with a NOT NULL column that has a default
  my $live = memory_dbh();
  $live->do(q{CREATE TABLE "t" ("id" INTEGER NOT NULL, "a" TEXT, PRIMARY KEY ("id"))});
  $live->do(q{INSERT INTO "t" ("id", "a") VALUES (1, 'a')});
  my ($deploy, $diff) = upgrade_to($live,
    q{CREATE TABLE "t" ("id" INTEGER NOT NULL, "a" TEXT, "b" TEXT NOT NULL DEFAULT 'd', PRIMARY KEY ("id"), UNIQUE ("a"))});
  lives_ok { $deploy->apply($diff) } 'a NOT NULL column with a default is added to a populated table';
  is($live->selectrow_array(q{SELECT b FROM "t"}), 'd', '... and the row has the default');
}

done_testing;
