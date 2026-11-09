use strict;
use warnings;
use Test::More;
use Test::Exception;

# t/47-diff-view.t -- the views of DBIO::ClickHouse::Diff (karr k43, core
# conformance cases diff-view-dropped and diff-view-definition-changed).
# Offline: hand-built models, no DBD, no DSN, no server.
#
# Claims:
#   1. A live view the schema does not declare is dropped (DROP VIEW), and
#      before any table operation: a table it selects from may go in the same
#      plan.
#   2. A declared view whose live definition differs is replaced in place with
#      CREATE OR REPLACE VIEW, after the table operations.
#   3. The comparison is the server's own text: the database name, the
#      quoting and the white space do not make a view "changed", or every
#      upgrade would replace every view.
#   4. A materialized view holds data. One the schema no longer declares, or
#      declares as a plain view, is a refusal naming it, thrown while the
#      operation list is built -- before any statement.
#   5. Without declared_views the diff has no opinion about views at all (the
#      library caller that hands none keeps the views it has).

use DBIO::ClickHouse::Diff;
use DBIO::ClickHouse::DDL::Emit qw(drop_view create_view);

sub table_info {
  my (%a) = @_;
  my @sorting = @{ $a{order_by} // ['id'] };
  return {
    table_name => $a{name}, kind => $a{kind} // 'table',
    engine => $a{engine} // 'MergeTree', engine_expression => $a{engine} // 'MergeTree',
    database => $a{database} // 'live',
    sorting_key => join(', ', @sorting), sorting_key_entries => \@sorting,
    primary_key => join(', ', @sorting), primary_key_entries => \@sorting,
    primary_key_columns => [ grep { /\A\w+\z/ } @sorting ],
    partition_key => '', partition_key_entries => [],
    (exists $a{definition} ? (definition => $a{definition}) : ()),
  };
}
sub view_info {
  my ($name, $definition, %a) = @_;
  return table_info(name => $name, kind => 'view', engine => $a{engine} // 'View',
    order_by => [], definition => $definition, database => $a{database});
}
sub model {
  my (%a) = @_;
  return { tables => $a{tables} // {}, columns => $a{columns} // {},
           data_skipping_indexes => {}, indexes => {}, foreign_keys => {} };
}
my $base_cols = { base => [ { column_name => 'id', data_type => 'Int32' } ] };
sub with_base {
  my (%views) = @_;
  return model(
    tables  => { base => table_info(name => 'base'), %views },
    columns => $base_cols,
  );
}
sub diff_of {
  my ($source, $target, $declared) = @_;
  return DBIO::ClickHouse::Diff->new(
    source => $source, target => $target,
    (defined $declared ? (declared_views => $declared) : ()),
  );
}

# --- the two statements ------------------------------------------------------
is drop_view(name => 'v'), 'DROP VIEW `v`;', 'drop_view renders DROP VIEW';
is drop_view(name => 'v', if_exists => 1), 'DROP VIEW IF EXISTS `v`;', '... with the guard when asked';
is create_view(name => 'v', definition => 'SELECT 1', or_replace => 1),
  'CREATE OR REPLACE VIEW `v` AS SELECT 1;', 'create_view renders OR REPLACE when asked';

# --- 1. dropped ---------------------------------------------------------------
{
  my $d = diff_of(
    with_base(old_v => view_info('old_v', 'SELECT id FROM live.base')),
    with_base(),
    {},
  );
  ok $d->has_changes, 'a live view the schema does not declare is a change';
  is $d->as_sql, 'DROP VIEW `old_v`;', '... DROP VIEW';
  like $d->summary, qr/- view: old_v/, '... and the summary names it';

  # a table dropped in the same plan: the view goes first
  my $with_table = diff_of(
    model(tables => { base => table_info(name => 'base'), gone => table_info(name => 'gone'),
                      old_v => view_info('old_v', 'SELECT id FROM live.gone') },
          columns => { base => [], gone => [] }),
    model(tables => { base => table_info(name => 'base') }, columns => { base => [] }),
    {},
  );
  like $with_table->as_sql, qr/DROP VIEW `old_v`;.*DROP TABLE `gone`;/s,
    'a view is dropped before the table operations';
}

# --- 2. replaced --------------------------------------------------------------
{
  my $src = with_base(v => view_info('v', 'SELECT id FROM live.base'));
  my $tgt = with_base(v => view_info('v', 'SELECT id, name FROM scratch.base', database => 'scratch'));
  my $d = diff_of($src, $tgt, { v => 'SELECT `id`, `name` FROM `base`' });
  ok $d->has_changes, 'a declared view with another definition is a change';
  is $d->as_sql, 'CREATE OR REPLACE VIEW `v` AS SELECT `id`, `name` FROM `base`;',
    '... CREATE OR REPLACE VIEW from the declared definition';
  like $d->summary, qr/~ view: v/, '... and the summary says changed';
}

# --- 3. the comparison is of the server's text --------------------------------
{
  my $src = with_base(v => view_info('v', "SELECT id,\n       name\nFROM live.base  WHERE id > 1"));
  my $tgt = with_base(v => view_info('v', 'SELECT id, name FROM scratch.base WHERE id > 1',
                                     database => 'scratch'));
  ok !diff_of($src, $tgt, { v => 'ignored when the target carries it' })->has_changes,
    'the database name and the white space are not a change';
}
{
  # a hand-built target without a definition: the declared text stands in, and
  # quoting is not a change either
  my $src = with_base(v => view_info('v', 'SELECT id, name FROM live.base'));
  my $tgt = with_base(v => table_info(name => 'v', kind => 'view', order_by => []));
  ok !diff_of($src, $tgt, { v => 'SELECT `id`, `name` FROM `base`' })->has_changes,
    'declared text without quoting marks is the same view';
  ok diff_of($src, $tgt, { v => 'SELECT `id` FROM `base`' })->has_changes,
    '... another selection is not';
}
{
  # a live view without a known definition is never replaced on a guess
  my $src = with_base(v => table_info(name => 'v', kind => 'view', order_by => []));
  my $tgt = with_base(v => table_info(name => 'v', kind => 'view', order_by => []));
  ok !diff_of($src, $tgt, { v => 'SELECT 1' })->has_changes,
    'a live view whose definition is unknown is left alone';
}

# --- 4. materialized views hold data -----------------------------------------
{
  my $mv = view_info('mv', 'SELECT id FROM live.base', engine => 'MaterializedView');
  my $src = with_base(mv => $mv);

  throws_ok { diff_of($src, with_base(), {})->has_changes }
    qr/refus.*`?mv`?.*MaterializedView/is,
    'a materialized view the schema does not declare is refused, by name';
  throws_ok { diff_of($src, with_base(), { mv => 'SELECT id FROM base' })->as_sql }
    qr/refus.*`?mv`?/is,
    'a plain view declared over a materialized one is refused, by name';
  like do { local $@; eval { diff_of($src, with_base(), {})->summary }; "$@" },
    qr/no statement|before/i, '... saying nothing was executed';
}

# --- 5. no declared views, no opinion ---------------------------------------
{
  my $src = with_base(old_v => view_info('old_v', 'SELECT id FROM live.base'),
                      mv => view_info('mv', 'SELECT 1', engine => 'MaterializedView'));
  ok !diff_of($src, with_base())->has_changes,
    'without declared_views no view is dropped or refused';
}

# --- the op order: replace and create come after the tables -------------------
{
  my $d = diff_of(
    with_base(v => view_info('v', 'SELECT id FROM live.base')),
    model(tables => { base => table_info(name => 'base'), extra => table_info(name => 'extra') },
          columns => { base => $base_cols->{base}, extra => [] }),
    { v => 'SELECT id, 1 FROM base' },
  );
  like $d->as_sql, qr/CREATE TABLE `extra`.*CREATE OR REPLACE VIEW `v`/s,
    'a replaced view comes after the tables it may select from';
}

done_testing;
