use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::DB2::Diff;
use DBIO::DB2::Diff::View;

# OFFLINE (karr k45, ADR 0011). The view operations of the diff, over mock models
# in the shape DBIO::DB2::Introspect makes: a view is an entry of the tables
# section with kind 'view' and a view_definition (what SYSCAT.VIEWS.TEXT holds
# after the view's name). Before k45 a view that differed made the diff die
# (karr k36); now it is CREATE VIEW / DROP VIEW, and never a table operation.
# The live counterpart is t/69.

sub view { my ($name, $def) = @_; return { table_name => $name, kind => 'view', view_definition => $def } }
sub model {
  my (%tables) = @_;
  return {
    tables  => { %tables },
    columns => { map { $_ => [ { column_name => 'id', catalog_type => 'INTEGER', catalog_size => 4, not_null => 1 } ] } keys %tables },
    indexes => {}, foreign_keys => {}, unique_constraints => {},
  };
}
sub tbl { return { table_name => $_[0], kind => 'table' } }
sub sql_of { my ($m1, $m2) = @_; return [ map { $_->as_sql } @{ DBIO::DB2::Diff->new(source => $m1, target => $m2)->operations } ] }

my $DEF = 'AS SELECT "id" FROM "t"';

# --- Diff::View alone ------------------------------------------------------
{
  my @ops = DBIO::DB2::Diff::View->diff({}, { v => view('v', $DEF) });
  is scalar(@ops), 1, 'a view only in the target: one operation';
  is $ops[0]->action, 'create', '... a create';
  is $ops[0]->as_sql, qq{CREATE VIEW "v" $DEF;}, '... CREATE VIEW, name quoted, definition as it is';
  like $ops[0]->summary, qr/\+ view: v/, '... summary';

  @ops = DBIO::DB2::Diff::View->diff({ v => view('v', $DEF) }, {});
  is scalar(@ops), 1, 'a view only in the source: one operation';
  is $ops[0]->as_sql, 'DROP VIEW "v";', '... DROP VIEW';
  ok !$ops[0]->replaced, '... not a replacement';
  like $ops[0]->summary, qr/- view: v/, '... summary';

  @ops = DBIO::DB2::Diff::View->diff({ v => view('v', $DEF) }, { v => view('v', $DEF) });
  is scalar(@ops), 0, 'an unchanged view: no operation';

  @ops = DBIO::DB2::Diff::View->diff(
    { v => view('v', 'AS SELECT "id"  FROM "t"') },
    { v => view('v', qq{AS SELECT "id"\n  FROM "t"\n}) });
  is scalar(@ops), 0, 'whitespace is no change';

  @ops = DBIO::DB2::Diff::View->diff({ v => view('v', $DEF) }, { v => view('v', 'AS SELECT "id", "x" FROM "t"') });
  is_deeply [ map { $_->action } @ops ], [qw(drop create)], 'a changed definition: drop, then create';
  ok $ops[0]->replaced, '... the drop is marked replaced';
  ok !$ops[1]->replaced, '... the create is not';
  is $ops[1]->as_sql, 'CREATE VIEW "v" AS SELECT "id", "x" FROM "t";', '... the create has the new definition';

  @ops = DBIO::DB2::Diff::View->diff({ v => view('v', undef) }, { v => view('v', 'AS SELECT 1 FROM t') });
  is scalar(@ops), 0, 'no definition on one side: nothing to compare, unchanged';

  @ops = DBIO::DB2::Diff::View->diff({ t => tbl('t') }, { t => tbl('t'), u => tbl('u') });
  is scalar(@ops), 0, 'tables are not looked at';

  @ops = DBIO::DB2::Diff::View->diff({}, { v => view('v', undef) });
  throws_ok { $ops[0]->as_sql } qr/Cannot create view "?v"?|Cannot create view v/,
    'a create without a definition throws, naming the view';
  lives_ok { $ops[0]->summary } '... the summary does not';
}

# --- through the orchestrator ------------------------------------------------
{
  # missing view, extra view, changed view, an unchanged one; beside tables
  my $source = model(t => tbl('t'), gone => view('gone', $DEF), same => view('same', $DEF),
                     chg => view('chg', 'AS SELECT 1 FROM "t"'), old_t => tbl('old_t'));
  my $target = model(t => tbl('t'), newv => view('newv', $DEF), same => view('same', $DEF),
                     chg => view('chg', 'AS SELECT 2 FROM "t"'), new_t => tbl('new_t'));
  my $diff = DBIO::DB2::Diff->new(source => $source, target => $target);
  my @sql  = map { $_->as_sql } @{ $diff->operations };

  my @view_drops   = grep { /^DROP VIEW/ } @sql;
  my @view_creates = grep { /^CREATE VIEW/ } @sql;
  is_deeply \@view_drops, [ 'DROP VIEW "gone";', 'DROP VIEW "chg";' ],
    'DROP VIEW for the surplus and the changed view';
  is_deeply \@view_creates, [ 'CREATE VIEW "chg" AS SELECT 2 FROM "t";', qq{CREATE VIEW "newv" $DEF;} ],
    'CREATE VIEW for the changed and the missing view';
  is_deeply [ grep { /TABLE/ } @sql ], [ 'CREATE TABLE "new_t" (' . "\n" . '  "id" INTEGER NOT NULL' . "\n);", 'DROP TABLE "old_t";' ],
    'tables: only the table operations, no table operation for a view'
    or diag join "\n", @sql;

  my ($first_create) = grep { $sql[$_] =~ /^CREATE VIEW/ } 0 .. $#sql;
  my ($last_drop)    = grep { $sql[$_] =~ /^DROP VIEW/ } reverse 0 .. $#sql;
  my ($create_table) = grep { $sql[$_] =~ /^CREATE TABLE/ } 0 .. $#sql;
  my ($drop_table)   = grep { $sql[$_] =~ /^DROP TABLE/ } 0 .. $#sql;
  ok $last_drop < $create_table && $last_drop < $drop_table, 'the view drops stand at the head, before any table operation';
  ok $first_create > $create_table && $first_create > $drop_table, 'the view creates stand at the end, behind the table operations';

  like $diff->summary, qr/- view: gone/, 'summary lists the dropped view';
  like $diff->summary, qr/\+ view: newv/, 'summary lists the created view';
}

# --- the same models, views unchanged: an empty diff --------------------------
{
  my $m = model(t => tbl('t'), v => view('v', $DEF));
  my $d = DBIO::DB2::Diff->new(source => $m, target => model(t => tbl('t'), v => view('v', $DEF)));
  ok !$d->has_changes, 'models with the same view: no changes';
}

# --- a view whose columns differ is not a column operation ---------------------
{
  my $src = model(v => view('v', $DEF));
  my $tgt = model(v => view('v', $DEF));
  push @{ $tgt->{columns}{v} }, { column_name => 'extra', catalog_type => 'INTEGER', catalog_size => 4 };
  my $d = DBIO::DB2::Diff->new(source => $src, target => $tgt);
  ok !$d->has_changes, 'columns of an unchanged view are not compared (the definition says what they are)';
}

# --- a table turned view ---------------------------------
{
  my $d = DBIO::DB2::Diff->new(source => model(x => tbl('x')), target => model(x => view('x', $DEF)));
  is_deeply [ map { $_->as_sql } @{ $d->operations } ], [ 'DROP TABLE "x";', qq{CREATE VIEW "x" $DEF;} ],
    'a table that becomes a view: DROP TABLE, CREATE VIEW';
}

done_testing;
