use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k79 (t/122 has the live half): a view is a view in the
# diff, never a table.
#
# WHY. The introspection lists a view under `tables` with kind => 'view', and
# the diff took it for a table: a view only the schema declares became a
# CREATE TABLE (an InnoDB table under the name of the view), one only the
# database has became DROP TABLE, which the server refuses on a view (1051),
# and its columns and indexes were diffed as a table's. A view that changed its
# definition but not its columns was no change at all.
#
# What the file claims:
#   1. a new view is a CREATE VIEW, after the CREATE TABLE of every new table;
#   2. a view that is gone is a DROP VIEW, before every table operation, and
#      never a DROP TABLE;
#   3. a view whose definition changed is a DROP VIEW and a CREATE VIEW, the drop
#      marked `replaced`, so the diff counts it as changing and not destructive
#      (core k352);
#   4. definitions are compared with whitespace set aside; the same view on both
#      sides is no operation;
#   5. Diff::Table, Diff::Column and Diff::Index, called by themselves, leave
#      every entry of kind 'view' alone -- its columns and indexes with it;
#   6. a create op without a definition is refused, and still has a summary.

use DBIO::MySQL::Diff;
use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::Diff::Column;
use DBIO::MySQL::Diff::Index;
use DBIO::MySQL::Diff::View;

sub tbl  { return { table_name => $_[0], kind => 'table', engine => 'InnoDB' } }
sub view { return { table_name => $_[0], kind => 'view', view_definition => $_[1] } }
sub col  { return { column_name => $_[0], data_type => 'int', column_type => 'int', not_null => 1 } }
sub model {
  my (%m) = @_;
  return { tables => {}, columns => {}, indexes => {}, foreign_keys => {}, %m };
}
sub sql { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

my $DEF  = 'select `item`.`id` AS `id` from `item`';
my $DEF2 = 'select `item`.`id` AS `id`,`item`.`n` AS `n` from `item`';

# 1. a new view
{
  my $diff = DBIO::MySQL::Diff->new(
    source => model(),
    target => model(
      tables  => { item => tbl('item'), v => view('v', $DEF) },
      columns => { item => [ col('id') ], v => [ col('id') ] },
    ),
  );
  my $sql = sql($diff);
  is scalar(@$sql), 2, 'a new view next to a new table: two statements' or diag explain $sql;
  like $sql->[0], qr/\ACREATE TABLE `item`/, '... the table first';
  is $sql->[1], "CREATE VIEW `v` AS $DEF;", '... then the view, as a view and with its definition';
  unlike join("\n", @$sql), qr/CREATE TABLE `v`/, '... and no table under the name of the view';
  is $diff->classify->{class}, 'additive', '... which is additive';
  is_deeply [ map { $_->summary } grep { $_->isa('DBIO::MySQL::Diff::View') } @{ $diff->operations } ],
    ['+ view: v'], '... and the summary says view';
}

# 2. a view that is gone
{
  my $diff = DBIO::MySQL::Diff->new(
    source => model(
      tables  => { item => tbl('item'), gone => tbl('gone'), v => view('v', $DEF) },
      columns => { item => [ col('id') ], gone => [ col('id') ], v => [ col('id') ] },
    ),
    target => model(
      tables  => { item => tbl('item') },
      columns => { item => [ col('id') ] },
    ),
  );
  is_deeply sql($diff), [ 'DROP VIEW `v`;', 'DROP TABLE `gone`;' ],
    'a view that is gone is a DROP VIEW, before the table operations, and no DROP TABLE'
    or diag explain sql($diff);
  is $diff->classify->{class}, 'destructive', '... and a removal is destructive';
}

# 3. a changed definition
{
  my $diff = DBIO::MySQL::Diff->new(
    source => model(
      tables  => { item => tbl('item'), v => view('v', $DEF) },
      columns => { item => [ col('id'), col('n') ], v => [ col('id') ] },
    ),
    target => model(
      tables  => { item => tbl('item'), v => view('v', $DEF2) },
      columns => { item => [ col('id'), col('n') ], v => [ col('id'), col('n') ] },
    ),
  );
  is_deeply sql($diff), [ 'DROP VIEW `v`;', "CREATE VIEW `v` AS $DEF2;" ],
    'a changed definition is a DROP VIEW and a CREATE VIEW, and no column operation on the view'
    or diag explain sql($diff);
  my ($drop) = @{ $diff->operations };
  ok $drop->replaced, '... the drop is marked replaced';
  my $c = $diff->classify;
  is $c->{class}, 'changing', '... so the diff is changing, not destructive'
    or diag explain $c;
  is $c->{counts}{destructive}, 0, '... with nothing destructive in it';
}

# 3b. the drop and create of a changed view stand around the tables
{
  my $diff = DBIO::MySQL::Diff->new(
    source => model(
      tables  => { item => tbl('item'), v => view('v', $DEF) },
      columns => { item => [ col('id') ] },
    ),
    target => model(
      tables  => { item => tbl('item'), other => tbl('other'), v => view('v', $DEF2) },
      columns => { item => [ col('id'), col('n') ], other => [ col('id') ] },
    ),
  );
  my $sql = sql($diff);
  is $sql->[0], 'DROP VIEW `v`;', 'a changed view is dropped before anything else';
  like $sql->[-1], qr/\ACREATE VIEW `v` AS /, '... and created after the new table and the new column'
    or diag explain $sql;
}

# 4. the same view
{
  my $diff = DBIO::MySQL::Diff->new(
    source => model(
      tables  => { v => view('v', $DEF) },
      columns => { v => [ col('id') ] },
    ),
    target => model(
      tables  => { v => view('v', "select  `item`.`id` AS `id`\n from `item`") },
      columns => { v => [ col('id') ] },
    ),
  );
  ok !$diff->has_changes, 'the same view, whitespace aside, is no change' or diag explain sql($diff);
}

# 5. the classes by themselves
{
  my @t = DBIO::MySQL::Diff::Table->diff(
    { old_v => view('old_v', $DEF) },
    { v => view('v', $DEF) },
    { v => [ col('a') ] },
  );
  is scalar(@t), 0, 'Diff::Table: a view is not created or dropped as a table' or diag explain [ map { $_->as_sql } @t ];

  my @c = DBIO::MySQL::Diff::Column->diff(
    { v => [ col('a') ], gone => [ col('a') ] },
    { v => [ col('a'), col('b') ], new => [ col('a') ] },
    { v => view('v', $DEF), gone => view('gone', $DEF) },
    { v => view('v', $DEF2), new => view('new', $DEF) },
  );
  is scalar(@c), 0, 'Diff::Column: no column of a view is added, changed or dropped' or diag explain [ map { $_->as_sql } @c ];

  my $ix = { index_name => 'i', columns => ['a'], is_unique => 0, index_type => 'BTREE', origin => 'c' };
  my @i = DBIO::MySQL::Diff::Index->diff(
    { gone => { i => $ix } },
    { new  => { i => $ix } },
    { gone => view('gone', $DEF) },
    { new  => view('new', $DEF) },
  );
  is scalar(@i), 0, 'Diff::Index: no index of a view is created or dropped' or diag explain [ map { $_->as_sql } @i ];

  # a table is still a table
  my @tt = DBIO::MySQL::Diff::Table->diff({}, { t => tbl('t') }, { t => [ col('a') ] });
  is scalar(@tt), 1, 'a table is still a table';
}

# 5b. a name that is a view in one model and a table in the other
{
  my $diff = DBIO::MySQL::Diff->new(
    source => model(tables => { x => view('x', $DEF) }, columns => { x => [ col('id') ] }),
    target => model(tables => { x => tbl('x') },        columns => { x => [ col('id') ] }),
  );
  is_deeply sql($diff)->[0], 'DROP VIEW `x`;', 'view to table: the view is dropped as a view'
    or diag explain sql($diff);
  like sql($diff)->[1], qr/\ACREATE TABLE `x`/, '... and the table created as a table';
}

# 6. no definition
{
  my ($op) = DBIO::MySQL::Diff::View->diff({}, { v => { table_name => 'v', kind => 'view' } });
  is $op->summary, '+ view: v', 'a view without a definition still has a summary';
  eval { $op->as_sql };
  like $@, qr/Cannot create view v:.*definition/, '... and its CREATE is refused, naming the view';
}

done_testing;
