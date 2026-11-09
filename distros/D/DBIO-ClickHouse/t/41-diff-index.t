use strict;
use warnings;
use Test::More;

# t/41-diff-index.t — DBIO::ClickHouse::Diff::Index over hand-built models.
# Offline: no DBD, no DSN, no server.
#
# Data-skipping indexes are not B-tree indexes and are not constraints, so this
# file exists to pin down that they are diffed on their OWN identity:
#
#   1. Their fields are expr / type_full / granularity. Core's
#      changed_index_fields compares is_unique and a columns list — neither of
#      which a skipping index has — so using it would report every index as
#      unchanged. set(100) and set(1000) are the same `type` and different
#      indexes; only type_full tells them apart.
#   2. They are ALTERed, never CREATEd: ADD INDEX / DROP INDEX on the table,
#      and inline in CREATE TABLE for a table that does not exist yet.
#   3. A DROP is only emitted when the target actually prescribes indexes for
#      that table. DBIO::ClickHouse::DDL cannot declare skipping indexes yet, so
#      an empty target section means "not prescribed", not "delete them all" —
#      reading it the other way would drop every hand-tuned index on the first
#      upgrade.
#   4. No standalone DROP INDEX for a table that is itself being dropped:
#      DROP TABLE already removes it, and the later statement would fail
#      against a real server (the sibling of dbio-duckdb k8).

use DBIO::ClickHouse::Diff;
use DBIO::ClickHouse::Diff::Index;

sub table_info {
  my ($name) = @_;
  return {
    table_name            => $name,
    kind                  => 'table',
    engine                => 'MergeTree',
    engine_expression     => 'MergeTree',
    sorting_key_entries   => ['id'],
    primary_key_entries   => ['id'],
    partition_key         => '',
    partition_key_entries => []
  };
}

sub skipping_index {
  my (%a) = @_;
  return {
    index_name  => $a{name},
    expr        => $a{expr}        // 'score',
    type        => $a{type}        // 'minmax',
    type_full   => $a{type_full}   // $a{type} // 'minmax',
    granularity => exists $a{granularity} ? $a{granularity} : 4
  };
}

sub model {
  my (%a) = @_;
  return {
    tables                => $a{tables}  // {},
    columns               => $a{columns} // {},
    data_skipping_indexes => $a{data_skipping_indexes} // {},
    indexes               => {},
    foreign_keys          => {}
  };
}

sub diff_of { DBIO::ClickHouse::Diff->new(source => $_[0], target => $_[1]) }

my $tables  = { metric => table_info('metric') };
my $columns = { metric => [
  { column_name => 'id',    data_type => 'UUID' },
  { column_name => 'score', data_type => 'Decimal(10, 2)' }
] };

# --- a new index on an existing table ---------------------------------------

my $added = diff_of(
  model(tables => $tables, columns => $columns),
  model(tables => $tables, columns => $columns, data_skipping_indexes => {
    metric => { metric_score_minmax => skipping_index(name => 'metric_score_minmax') }
  })
);

is scalar @{ $added->operations }, 1, 'one operation for one added skipping index';
is $added->as_sql,
  'ALTER TABLE `metric` ADD INDEX `metric_score_minmax` score TYPE minmax GRANULARITY 4;',
  'a new skipping index is an ALTER TABLE ADD INDEX, not a CREATE INDEX';
like $added->summary, qr/\+skipping index: metric_score_minmax on metric/,
  'summary calls it a skipping index, not an index';

# MATERIALIZE INDEX rewrites every existing part. That is a capacity decision,
# so an upgrade must never kick it off on its own.
unlike $added->as_sql, qr/MATERIALIZE/,
  'ADD INDEX is not followed by an automatic MATERIALIZE INDEX mutation';

# The indexed expression is an expression, not an identifier.
like diff_of(
  model(tables => $tables, columns => $columns),
  model(tables => $tables, columns => $columns, data_skipping_indexes => {
    metric => { i => skipping_index(name => 'i', expr => 'lower(name)') }
  })
)->as_sql, qr/ADD INDEX `i` lower\(name\) TYPE/,
  'the indexed expression is emitted verbatim, never backtick-quoted';

# --- a changed definition is a drop-then-add pair ----------------------------

for my $case (
  [ 'expression',  { expr        => 'score * 2' } ],
  [ 'granularity', { granularity => 16 } ],
  [ 'type arguments', { type => 'set', type_full => 'set(1000)' } ]
) {
  my ($label, $override) = @$case;

  my $changed = diff_of(
    model(tables => $tables, data_skipping_indexes => {
      metric => { i => skipping_index(name => 'i', type => 'set', type_full => 'set(100)') }
    }),
    model(tables => $tables, data_skipping_indexes => {
      metric => { i => skipping_index(name => 'i', type => 'set', type_full => 'set(100)',
                                      %$override) }
    })
  );

  my @ops = @{ $changed->operations };
  is scalar @ops, 2, "a changed $label is a drop-then-add pair (there is no ALTER INDEX)";
  is $ops[0]->action, 'drop', "  ... $label: the drop comes first";
  is $ops[1]->action, 'add',  "  ... $label: then the add";
}

# set(100) and set(1000) share a `type`; only type_full distinguishes them.
ok diff_of(
  model(tables => $tables, data_skipping_indexes => {
    metric => { i => skipping_index(name => 'i', type => 'set', type_full => 'set(100)') } }),
  model(tables => $tables, data_skipping_indexes => {
    metric => { i => skipping_index(name => 'i', type => 'set', type_full => 'set(1000)') } })
)->has_changes, 'type_full is what distinguishes set(100) from set(1000)';

# An identical index pair is clean.
my $same = model(tables => $tables, data_skipping_indexes => {
  metric => { i => skipping_index(name => 'i') } });
ok !diff_of($same, $same)->has_changes, 'an unchanged skipping index produces nothing';

# --- removed indexes, and the unprescribed-section guard ---------------------

# The target declares indexes for this table, so an index missing from it is a
# real removal.
my $gone = diff_of(
  model(tables => $tables, data_skipping_indexes => {
    metric => {
      keep => skipping_index(name => 'keep'),
      old  => skipping_index(name => 'old', expr => 'id')
    }
  }),
  model(tables => $tables, data_skipping_indexes => {
    metric => { keep => skipping_index(name => 'keep') }
  })
);
is scalar @{ $gone->operations }, 1, 'only the removed index produces an operation';
is $gone->as_sql, 'ALTER TABLE `metric` DROP INDEX `old`;',
  'an index removed from a table that still prescribes indexes is dropped';

# The target carries no skipping index for this table at all. That is a
# removal too (karr k43): the index must be droppable when the column it reads
# goes with it, and the schema is the single owner of what the table keeps.
my $last_gone = diff_of(
  model(tables => $tables, data_skipping_indexes => {
    metric => { handmade => skipping_index(name => 'handmade') }
  }),
  model(tables => $tables)
);
is $last_gone->as_sql, 'ALTER TABLE `metric` DROP INDEX `handmade`;',
  'the last skipping index of a table goes when the target carries none';

# A table with no skipping index on either side stays quiet.
ok !diff_of(model(tables => $tables), model(tables => $tables))->has_changes,
  'no index on either side, nothing to do';

# --- a table being dropped in the same pass ---------------------------------

my $table_dropped = diff_of(
  model(
    tables  => { leftover => table_info('leftover') },
    data_skipping_indexes => {
      leftover => { i => skipping_index(name => 'i') }
    }
  ),
  model()
);
my $sql = $table_dropped->as_sql;
like   $sql, qr/DROP TABLE `leftover`;/, 'the removed table is dropped';
unlike $sql, qr/DROP INDEX/,
  'no standalone DROP INDEX for it — DROP TABLE already removed the index, and '
. 'the later statement would fail against a real server';

# The guard must not over-suppress: a table that SURVIVES and prescribes
# indexes still gets its removed index dropped standalone.
like diff_of(
  model(tables => $tables, data_skipping_indexes => {
    metric => { keep => skipping_index(name => 'keep'),
                old  => skipping_index(name => 'old') } }),
  model(tables => $tables, data_skipping_indexes => {
    metric => { keep => skipping_index(name => 'keep') } })
)->as_sql, qr/DROP INDEX `old`/, 'a surviving table still loses a removed index';

# --- a brand-new table carries its indexes inline ---------------------------
# ClickHouse declares skipping indexes inside CREATE TABLE. Emitting them as a
# follow-up ALTER would work, but the table body is where they belong and where
# SHOW CREATE TABLE puts them back.

my $created = diff_of(model(), model(
  tables  => $tables,
  columns => $columns,
  data_skipping_indexes => {
    metric => {
      metric_score_minmax => skipping_index(name => 'metric_score_minmax'),
      metric_id_set       => skipping_index(name => 'metric_id_set', expr => 'id',
                                            type => 'set', type_full => 'set(100)',
                                            granularity => 1)
    }
  }
))->as_sql;

like $created, qr/CREATE TABLE `metric`/, 'the new table is created';
like $created, qr/  INDEX `metric_score_minmax` score TYPE minmax GRANULARITY 4/,
  'its skipping index is inline in the table body';
like $created, qr/  INDEX `metric_id_set` id TYPE set\(100\) GRANULARITY 1/,
  'and so is the second one, with its own type arguments';
unlike $created, qr/ADD INDEX/,
  'a new table gets no follow-up ALTER TABLE ADD INDEX';

# The index entries must come after the columns, or the CREATE TABLE is invalid.
my ($body) = $created =~ /\((.*)\)/s;
ok index($body, '`score` Decimal(10, 2)') < index($body, 'INDEX `metric_id_set`'),
  'indexes are emitted after the column definitions';

# --- granularity is optional ------------------------------------------------

is DBIO::ClickHouse::Diff::Index::index_def(
  { index_name => 'i', expr => 'x', type_full => 'minmax', granularity => undef }
), 'INDEX `i` x TYPE minmax',
  'an index with no granularity omits the clause and takes the server default';

# --- a dropped column that carries an index ----------------------------------
# WHY: the server refuses ALTER TABLE ... DROP COLUMN c while a skipping index
# reads c ("Cannot apply mutation because it breaks skip index"; measured on
# 25.3). The DROP INDEX has to be sent before the DROP COLUMN, whatever the
# order the two walks run in. A re-added definition (drop-then-add) still has
# to follow the column it reads, so only the drops move up.

{
  my $cols_src = { metric => [
    { column_name => 'id',    data_type => 'UUID' },
    { column_name => 'score', data_type => 'Decimal(10, 2)' },
    { column_name => 'gone',  data_type => 'Int32' },
  ] };
  my $sql = diff_of(
    model(tables => $tables, columns => $cols_src, data_skipping_indexes => {
      metric => { keep => skipping_index(name => 'keep'),
                  on_gone => skipping_index(name => 'on_gone', expr => 'gone') } }),
    model(tables => $tables, columns => $columns, data_skipping_indexes => {
      metric => { keep => skipping_index(name => 'keep') } })
  )->as_sql;
  my $di = index $sql, 'DROP INDEX `on_gone`';
  my $dc = index $sql, 'DROP COLUMN `gone`';
  ok $di >= 0 && $dc >= 0, 'both the index and its column are dropped';
  ok $di < $dc, 'the DROP INDEX comes before the DROP COLUMN it depends on';
}

# The same, when the dropped column carried the table's ONLY index: the target
# then has no skipping index at all, and the drop must still precede the column.
{
  my $cols_src = { metric => [
    { column_name => 'id', data_type => 'UUID' },
    { column_name => 'x',  data_type => 'Int32' },
  ] };
  my $cols_tgt = { metric => [ { column_name => 'id', data_type => 'UUID' } ] };
  my $sql = diff_of(
    model(tables => $tables, columns => $cols_src, data_skipping_indexes => {
      metric => { on_x => skipping_index(name => 'on_x', expr => 'x') } }),
    model(tables => $tables, columns => $cols_tgt)
  )->as_sql;
  my $di = index $sql, 'DROP INDEX `on_x`';
  my $dc = index $sql, 'DROP COLUMN `x`';
  ok $di >= 0 && $dc >= 0, 'the last index and its column are both dropped';
  ok $di < $dc, 'the DROP INDEX of the last index comes before the DROP COLUMN';
}

done_testing;
