use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBI;
use DBIO::Deploy::Base;
use DBIO::SQLite::Deploy;
use DBIO::SQLite::Diff;
use DBIO::SQLite::Diff::Column;
use DBIO::SQLite::Introspect;
use DBIO::SQLite::Util qw(type_affinity);

# core karr k399, ADR 0080 -- the deploy class runs a diff through the hooks of
# DBIO::Deploy::Base, and a change that may alter a stored value is released
# with allow_destructive like a drop.

{
  package Lossy::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}

# --- 1. the deploy class inherits apply and upgrade ---------------------------
{
  for my $method (qw(apply upgrade)) {
    ok(!defined &{"DBIO::SQLite::Deploy::$method"},
      "DBIO::SQLite::Deploy defines no $method of its own");
    is(DBIO::SQLite::Deploy->can($method), DBIO::Deploy::Base->can($method),
      "$method is the one of DBIO::Deploy::Base");
  }
  for my $hook (qw(_check_before_apply _execute_diff)) {
    isnt(DBIO::SQLite::Deploy->can($hook), DBIO::Deploy::Base->can($hook),
      "$hook is the driver's own");
  }
}

# --- 2. the pairs: same affinity, and SQLite really keeps every value ---------
my $pairs = DBIO::SQLite::Diff::Column->lossless_type_pairs;
{
  ok(scalar keys %$pairs, 'there are lossless pairs');
  for my $pair (sort keys %$pairs) {
    my ($from, $to) = split /->/, $pair, 2;
    is(type_affinity($from), type_affinity($to), "$pair: one affinity");
  }

  my @values = (
    1, -7, 0, '9223372036854775807', 1.5, 1.0, '12', '007', 'abc', '1e3',
    '', 'x' x 300, 0.1, '2024-01-15',
  );
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  my $n = 0;
  for my $pair (sort keys %$pairs) {
    my ($from, $to) = split /->/, $pair, 2;
    $n++;
    $dbh->do(qq{CREATE TABLE "a$n" (id INTEGER PRIMARY KEY, v $from)});
    $dbh->do(qq{CREATE TABLE "b$n" (id INTEGER PRIMARY KEY, v $to)});
    $dbh->do(qq{INSERT INTO "a$n" (v) VALUES (?)}, undef, $_) for @values;
    $dbh->do(qq{INSERT INTO "a$n" (v) VALUES (NULL)});
    $dbh->do(qq{INSERT INTO "b$n" (id, v) SELECT id, v FROM "a$n"});
    my $rows = $dbh->selectall_arrayref(
      qq{SELECT a.id, typeof(a.v), a.v, typeof(b.v), b.v
         FROM "a$n" a JOIN "b$n" b USING (id) ORDER BY a.id});
    my @changed = grep {
      $_->[1] ne $_->[3] || (defined $_->[2] xor defined $_->[4])
        || (defined $_->[2] && $_->[2] ne $_->[4])
    } @$rows;
    is(scalar @changed, 0, "$pair: the rebuild's copy keeps every value and its class")
      or diag explain \@changed;
  }

  # The converse, for the claim that a change of affinity is not on the list.
  for my $pair ('integer->real', 'integer->text', 'text->integer', 'real->integer') {
    ok(!$pairs->{$pair}, "$pair is not lossless");
  }
  ok(!$pairs->{'geometry->text'}, 'a type the list does not know is not lossless');
}

# --- 3. the answer of the column op -------------------------------------------
{
  my $lossy = sub {
    my ($action, $from, $to, %extra) = @_;
    return DBIO::SQLite::Diff::Column->new(
      action => $action, table_name => 't', column_name => 'c',
      old_info => { column_name => 'c', data_type => $from, %{ $extra{old} || {} } },
      new_info => { column_name => 'c', data_type => $to,   %{ $extra{new} || {} } },
    )->lossy;
  };

  ok(!$lossy->(alter => 'VARCHAR', 'TEXT'),       'VARCHAR -> TEXT keeps every value');
  ok(!$lossy->(alter => 'INTEGER', 'BIGINT'),     'INTEGER -> BIGINT keeps every value');
  ok(!$lossy->(alter => 'INTEGER', 'INTEGER'),    'same type, same size');
  ok($lossy->(alter => 'INTEGER', 'TEXT'),        'INTEGER -> TEXT is lossy');
  ok($lossy->(alter => 'INTEGER', 'REAL'),        'INTEGER -> REAL is lossy');
  ok($lossy->(alter => 'TEXT', 'INTEGER'),        'TEXT -> INTEGER is lossy');
  ok($lossy->(alter => 'GEOMETRY', 'TEXT'),       'an unknown type is lossy');
  ok($lossy->(alter => 'VARCHAR', 'VARCHAR', old => { size => 100 }, new => { size => 10 }),
    'a smaller size of one type is lossy');
  ok(!$lossy->(alter => 'VARCHAR', 'VARCHAR', old => { size => 10 }, new => { size => 100 }),
    'a larger size of one type is not');
  ok(!$lossy->(add  => 'INTEGER', 'TEXT'), 'an add loses nothing');
  ok(!$lossy->(drop => 'INTEGER', 'TEXT'), 'a drop is destructive by its action, not lossy');
}

# --- 4. the guard, through the inherited apply ---------------------------------
sub memory_dbh {
  return DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

sub upgrade_to {
  my ($live, @target_sql) = @_;
  my $target = memory_dbh();
  $target->do($_) for @target_sql;
  my $model = sub { DBIO::SQLite::Introspect->new(dbh => $_[0])->model };
  my $diff = DBIO::SQLite::Diff->new(source => $model->($live), target => $model->($target));
  my $deploy = DBIO::SQLite::Deploy->new(schema => Lossy::Schema->connect(sub { $live }));
  return ($deploy, $diff);
}

sub live_table {
  my ($type) = @_;
  my $dbh = memory_dbh();
  $dbh->do(qq{CREATE TABLE "item" ("id" INTEGER NOT NULL, "v" $type, "w" TEXT, PRIMARY KEY ("id"))});
  $dbh->do(q{INSERT INTO "item" VALUES (1, 12, 'x')});
  return $dbh;
}

{
  my $live = live_table('INTEGER');
  my ($deploy, $diff) = upgrade_to($live,
    q{CREATE TABLE "item" ("id" INTEGER NOT NULL, "v" TEXT, "w" TEXT, PRIMARY KEY ("id"))});
  ok($diff->has_changes, 'INTEGER -> TEXT is a change');
  is(scalar($diff->destructive_operations), 1, 'the rebuild reports the lossy change');

  throws_ok { $deploy->apply($diff) } qr/allow_destructive/,
    'a lossy rebuild is refused without allow_destructive';
  is($live->selectrow_array(q{SELECT typeof(v) FROM item}), 'integer',
    'nothing has run: the value is as it was');

  lives_ok { $deploy->apply($diff, allow_destructive => 1) }
    'it runs with allow_destructive';
  is($live->selectrow_array(q{SELECT typeof(v) FROM item}), 'text',
    'and the column now has the new type');
}

{
  my $live = live_table('VARCHAR(10)');
  my ($deploy, $diff) = upgrade_to($live,
    q{CREATE TABLE "item" ("id" INTEGER NOT NULL, "v" TEXT, "w" TEXT, PRIMARY KEY ("id"))});
  ok($diff->has_changes, 'VARCHAR -> TEXT is a change');
  is(scalar($diff->destructive_operations), 0, 'it is not lossy');
  lives_ok { $deploy->apply($diff) } 'it runs without allow_destructive';
  is($live->selectrow_array(q{SELECT v FROM item}), 12, 'the value is kept');
}

{
  my $live = live_table('INTEGER');
  my ($deploy, $diff) = upgrade_to($live,
    q{CREATE TABLE "item" ("id" INTEGER NOT NULL, "v" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"))});
  is(scalar($diff->destructive_operations), 1,
    'a column dropped by a rebuild is reported as well');
  throws_ok { $deploy->apply($diff) } qr/allow_destructive/,
    'the rebuild that drops a column needs allow_destructive';
}

done_testing;
