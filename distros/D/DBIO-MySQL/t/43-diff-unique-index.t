use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Diff;
use DBIO::MySQL::Diff::Index;

# karr k70: a unique index is an index, and the diff has to treat it as one.
#
# WHY IT MATTERS. DBIO::MySQL::Introspect::Indexes gives origin 'u' to every
# unique index that is not the PRIMARY KEY -- on MySQL and MariaDB a UNIQUE
# constraint IS a unique index, the server keeps nothing else for it.
# Diff::Index used to skip origin 'u' together with 'pk' (a rule taken over
# from the SQLite driver, where 'u' is the auto-index of an inline UNIQUE
# constraint that the table rebuild carries). Nothing else in this driver's
# diff covers a unique index: Diff::Table writes columns, the primary key and
# the foreign keys into CREATE TABLE, Diff::Column knows no uniqueness. So a
# unique key that was added to, changed in or removed from a schema never
# reached the database on upgrade, has_changes said 0, and a table created by
# an upgrade came up without its unique key -- duplicates went in where the
# schema forbade them.
#
# Every model below has the shape the introspection really produces for a
# unique index (is_unique => 1, origin => 'u', index_type => 'BTREE'), and is
# sent through DBIO::MySQL::Diff as a whole, the way DBIO::MySQL::Deploy does
# it: the question is not whether one class can render a statement but whether
# the diff of two models SAYS anything.
#
# The live half is t/84-diff-unique-index-live.t.

# One index entry as DBIO::MySQL::Introspect::Indexes->fetch returns it.
sub unique_index {
  my ($name, @columns) = @_;
  return ($name => {
    index_name => $name, is_unique => 1, columns => [@columns],
    index_type => 'BTREE', origin => 'u',
  });
}
sub plain_index {
  my ($name, @columns) = @_;
  return ($name => {
    index_name => $name, is_unique => 0, columns => [@columns],
    index_type => 'BTREE', origin => 'c',
  });
}
sub primary_index {
  return (PRIMARY => {
    index_name => 'PRIMARY', is_unique => 1, columns => ['id'],
    index_type => 'BTREE', origin => 'pk',
  });
}

my @USER_COLUMNS = (
  { column_name => 'id',     data_type => 'int',     column_type => 'int(11)',      not_null => 1, is_pk => 1 },
  { column_name => 'email',  data_type => 'varchar', column_type => 'varchar(190)', not_null => 1 },
  { column_name => 'tenant', data_type => 'int',     column_type => 'int(11)',      not_null => 1 },
);

# A model with the one table `users` and the given indexes on it.
sub users_model {
  my (%indexes) = @_;
  return {
    tables       => { users => { table_name => 'users', engine => 'InnoDB' } },
    columns      => { users => [ map { +{ %$_ } } @USER_COLUMNS ] },
    indexes      => { users => { primary_index(), %indexes } },
    foreign_keys => {},
  };
}
my $EMPTY = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };

# The statements of a diff, one per element, in the order they would run.
sub statements {
  my ($source, $target) = @_;
  my $diff = DBIO::MySQL::Diff->new(source => $source, target => $target);
  return ($diff, [ map { $_->as_sql } @{ $diff->operations } ]);
}

# ---------------------------------------------------------------------------
# 1. A unique key added to a table that is already there
# ---------------------------------------------------------------------------
{
  my ($diff, $sql) = statements(
    users_model(),
    users_model(unique_index(uniq_users_email => 'email')),
  );
  ok $diff->has_changes, 'added: a unique index the database lacks is a change';
  is_deeply $sql, [ 'CREATE UNIQUE INDEX `uniq_users_email` ON `users` (`email`) USING BTREE;' ],
    '... and the diff creates it, as a UNIQUE index';
  like $diff->summary, qr/\+index: uniq_users_email on users/, '... and names it in the summary';
}

# ---------------------------------------------------------------------------
# 2. The columns of a unique key changed
# ---------------------------------------------------------------------------
{
  my ($diff, $sql) = statements(
    users_model(unique_index(uniq_users_email => 'email')),
    users_model(unique_index(uniq_users_email => 'tenant', 'email')),
  );
  ok $diff->has_changes, 'changed: a unique index over other columns is a change';
  is_deeply $sql, [
    'DROP INDEX `uniq_users_email` ON `users`;',
    'CREATE UNIQUE INDEX `uniq_users_email` ON `users` (`tenant`, `email`) USING BTREE;',
  ], '... dropped and created again over the columns the schema names, in their order';
}

# ---------------------------------------------------------------------------
# 3. A unique key removed
# ---------------------------------------------------------------------------
{
  my ($diff, $sql) = statements(
    users_model(unique_index(uniq_users_email => 'email')),
    users_model(),
  );
  ok $diff->has_changes, 'removed: a unique index the schema no longer has is a change';
  is_deeply $sql, [ 'DROP INDEX `uniq_users_email` ON `users`;' ], '... and the diff drops it';
}

# ---------------------------------------------------------------------------
# 4. A new table that has a unique key
# ---------------------------------------------------------------------------
# CREATE TABLE of Diff::Table carries no index but the primary key, so the
# unique key has to follow it as a statement of its own -- after the table.
{
  my ($diff, $sql) = statements(
    $EMPTY,
    users_model(unique_index(uniq_users_email => 'email')),
  );
  is scalar(@$sql), 2, 'new table: two statements'
    or diag explain $sql;
  like $sql->[0], qr/\ACREATE TABLE `users` \(/, '... the table first';
  unlike $sql->[0], qr/UNIQUE/, '... which does not carry the unique key itself';
  is $sql->[1], 'CREATE UNIQUE INDEX `uniq_users_email` ON `users` (`email`) USING BTREE;',
    '... then its unique index';
}

# ---------------------------------------------------------------------------
# 5. Unique or not is itself compared
# ---------------------------------------------------------------------------
# Same name, same columns: only is_unique differs (and with it the origin the
# introspection gives). Making an index unique, or giving the uniqueness up,
# is a change in what the database enforces.
for my $case (
  [ 'made unique',       { plain_index(idx_users_email => 'email') },  { unique_index(idx_users_email => 'email') },
    'CREATE UNIQUE INDEX `idx_users_email` ON `users` (`email`) USING BTREE;' ],
  [ 'no longer unique',  { unique_index(idx_users_email => 'email') }, { plain_index(idx_users_email => 'email') },
    'CREATE INDEX `idx_users_email` ON `users` (`email`) USING BTREE;' ],
) {
  my ($name, $have, $want, $create) = @$case;
  my ($diff, $sql) = statements(users_model(%$have), users_model(%$want));
  is_deeply $sql, [ 'DROP INDEX `idx_users_email` ON `users`;', $create ],
    "$name: an index over the same columns is dropped and created again";
}

# ---------------------------------------------------------------------------
# 6. What must stay quiet
# ---------------------------------------------------------------------------
# A unique index that is the same on both sides is no change: an upgrade of a
# schema nobody touched must not rebuild its unique keys.
{
  my ($diff, $sql) = statements(
    users_model(unique_index(uniq_users_email => 'email')),
    users_model(unique_index(uniq_users_email => 'email')),
  );
  ok !$diff->has_changes, 'unchanged: a unique index that is the same on both sides is no change'
    or diag explain $sql;
}

# The PRIMARY KEY is still not an index statement. It is written into CREATE
# TABLE by Diff::Table, and no CREATE INDEX can name it: `PRIMARY` is not a
# name the server takes for one. Asked on every path an index can take --
# new, changed, gone -- because the rule that used to skip 'u' skipped 'pk'
# in the same breath, and only one of the two was wrong.
{
  my %other_pk = (PRIMARY => {
    index_name => 'PRIMARY', is_unique => 1, columns => ['id', 'tenant'],
    index_type => 'BTREE', origin => 'pk',
  });
  my @new     = DBIO::MySQL::Diff::Index->diff({}, { users => { primary_index() } });
  my @changed = DBIO::MySQL::Diff::Index->diff({ users => { primary_index() } }, { users => { %other_pk } });
  my @gone    = DBIO::MySQL::Diff::Index->diff({ users => { primary_index() } }, { users => {} });
  is scalar(@new),     0, 'the PRIMARY KEY of a new table is not created as an index';
  is scalar(@changed), 0, '... a changed one is not dropped and created as an index';
  is scalar(@gone),    0, '... and one that is gone is not dropped as an index';

  my ($diff, $sql) = statements($EMPTY, users_model());
  is scalar(@$sql), 1, 'a new table with only a primary key is one statement, the CREATE TABLE'
    or diag explain $sql;
}

# The unique index of a table that is dropped in the same run goes with the
# table (karr k23): DROP TABLE takes it, and a DROP INDEX after it would name
# a table that is no longer there.
{
  my ($diff, $sql) = statements(
    users_model(unique_index(uniq_users_email => 'email')),
    $EMPTY,
  );
  is_deeply $sql, [ 'DROP TABLE `users`;' ],
    'dropped table: its unique index is not dropped on its own';
}

done_testing;
