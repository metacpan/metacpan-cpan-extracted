use strict;
use warnings;
use Test::More;

# t/44-diff-if-exists.t — DBIO::ClickHouse::Diff emits IF [NOT] EXISTS guards
# when the storage declares the F12 capability, and stays bare when it does not.
# Offline: no DBD, no DSN, no server.
#
# ClickHouse parses IF EXISTS / IF NOT EXISTS on every object kind this driver
# emits DDL for EXCEPT MODIFY COLUMN (t/38-ddl-if-exists-live.t is the probe
# for that; MODIFY is deliberately not in the list). karr k20 wired the F12
# helper to the diff ops so that re-applying a diff after a partial failure
# becomes a no-op rather than an error.
#
# This file nails down two complementary facts, and its assertions are
# deliberately the inverse of each other on the SAME model so that the
# capability bit is the only thing moving:
#
#   1. With a fake storage that reports the capability, every emitted statement
#      carries the IF [NOT] EXISTS guard -- WITHOUT modifying the model. Without
#      this wiring (karr k20), the same diff against the same model emits the
#      plain unguarded statements that t/40 and t/41 already pin.
#   2. With no storage attached, every statement stays bare -- the helper
#      returns 0 conservatively when no storage is present, so the legacy
#      unguarded behavior of t/40 and t/41 is preserved for any caller that
#      has not opted in to the capability yet.
#
# MODIFY COLUMN is asserted to stay unguarded on BOTH sides of the capability
# bit: ClickHouse has no IF [NOT] EXISTS for it (that is the one form t/38
# verifies by negative space), and Emit does not accept the parameter.

use DBIO::ClickHouse::DDL;
use DBIO::ClickHouse::DDL::Emit qw(
  quote_ident column_def index_def
  create_table drop_table
  alter_table_add_column alter_table_modify_column alter_table_drop_column
  alter_table_add_index alter_table_drop_index
);
use DBIO::ClickHouse::Diff;

# --- mock storage: declares the F12 capability -------------------------------
# All we need is the _use_supports_if_exists accessor; DBIO::Diff::Op
# ::should_emit_if_exists probes exactly that, defensively (can() check).
package DBIO::ClickHouse::Test::FakeStorage_IFExists;
sub new { bless {}, shift }
sub _use_supports_if_exists { 1 }

package main;

sub table_info {
  my (%a) = @_;
  my @sorting = @{ $a{order_by} // ['id'] };
  return {
    table_name            => $a{name},
    kind                  => 'table',
    engine                => 'MergeTree',
    engine_expression     => 'MergeTree',
    sorting_key_entries   => \@sorting,
    primary_key_entries   => \@sorting,
    partition_key         => '',
    partition_key_entries => []
  };
}

sub column {
  my ($name, $type, %a) = @_;
  return { column_name => $name, data_type => $type, %a };
}

sub skipping_index {
  my (%a) = @_;
  return {
    index_name  => $a{name},
    expr        => $a{expr}      // 'score',
    type_full   => $a{type_full} // 'minmax',
    granularity => $a{granularity} // 4
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

sub diff_with_storage {
  my ($source, $target, $storage) = @_;
  DBIO::ClickHouse::Diff->new(
    source  => $source,
    target  => $target,
    storage => $storage,
  );
}

sub diff_no_storage {
  my ($source, $target) = @_;
  DBIO::ClickHouse::Diff->new(source => $source, target => $target);
}

my $mock = DBIO::ClickHouse::Test::FakeStorage_IFExists->new;

# --- 1. CREATE TABLE / DROP TABLE --------------------------------------------

my $tables  = {
  event  => table_info(name => 'event',  order_by => ['id']),
  metric => table_info(name => 'metric', order_by => ['id']),
};
my $columns = {
  event  => [
    { column_name => 'id',    data_type => 'UUID' },
    { column_name => 'score', data_type => 'Int64' }
  ],
  metric => [
    { column_name => 'id',   data_type => 'UUID' },
    { column_name => 'score', data_type => 'Int64' }
  ],
};

my $new_table = diff_with_storage(
  model(),
  model(tables => $tables, columns => $columns),
  $mock,
);

# CREATE TABLE IF NOT EXISTS — the new table is created
like $new_table->as_sql,
  qr/CREATE TABLE IF NOT EXISTS `event`/,
  'CREATE TABLE IF NOT EXISTS when storage declares the capability';
# No DROP TABLE when target has every source table
unlike $new_table->as_sql, qr/DROP TABLE/,
  '  ... and there is no DROP TABLE in the same script';

my $drop_table = diff_with_storage(
  model(tables => $tables, columns => $columns), model(),
  $mock,
);
like $drop_table->as_sql,
  qr/DROP TABLE IF EXISTS `event`/,
  'DROP TABLE IF EXISTS when storage declares the capability (karr k20 design '
. 'decision: the partial-failure-reapply scenario needs the guard on DROP as '
. 'well as CREATE)';

# --- 2. ADD COLUMN / DROP COLUMN --------------------------------------------

my $base_tables  = { user => table_info(name => 'user', order_by => ['id']) };
my $base_columns = { user => [
  { column_name => 'id',   data_type => 'UUID' },
  { column_name => 'name', data_type => 'String' }
] };

my $added_col = diff_with_storage(
  model(tables => $base_tables, columns => $base_columns),
  model(tables => $base_tables, columns => { user => [
    @{ $base_columns->{user} }, { column_name => 'email', data_type => 'Nullable(String)' }
  ] }),
  $mock,
);
like $added_col->as_sql,
  qr/ALTER TABLE `user` ADD COLUMN IF NOT EXISTS `email` Nullable\(String\)/,
  'ADD COLUMN IF NOT EXISTS when storage declares the capability';

my $dropped_col = diff_with_storage(
  model(tables => $base_tables, columns => { user => [
    @{ $base_columns->{user} }, { column_name => 'legacy', data_type => 'String' }
  ] }),
  model(tables => $base_tables, columns => $base_columns),
  $mock,
);
like $dropped_col->as_sql,
  qr/ALTER TABLE `user` DROP COLUMN IF EXISTS `legacy`/,
  'DROP COLUMN IF EXISTS when storage declares the capability';

# --- 3. ADD INDEX / DROP INDEX -----------------------------------------------

my $index_added = diff_with_storage(
  model(tables => $tables, columns => $columns),
  model(tables => $tables, columns => $columns,
        data_skipping_indexes => {
          metric => { idx => skipping_index(name => 'idx') }
        }),
  $mock,
);
like $index_added->as_sql,
  qr/ALTER TABLE `metric` ADD INDEX IF NOT EXISTS `idx`/,
  'ADD INDEX IF NOT EXISTS when storage declares the capability';

my $index_dropped = diff_with_storage(
  model(tables => $tables, columns => $columns,
        data_skipping_indexes => {
          metric => { idx => skipping_index(name => 'idx') }
        }),
  model(tables => $tables, columns => $columns,
        data_skipping_indexes => {
          metric => { keep => skipping_index(name => 'keep') }
        }),
  $mock,
);
like $index_dropped->as_sql,
  qr/ALTER TABLE `metric` DROP INDEX IF EXISTS `idx`/,
  'DROP INDEX IF EXISTS when storage declares the capability';

# --- 4. MODIFY COLUMN -- no guard on ClickHouse -----------------------------
# ClickHouse has no IF [NOT] EXISTS form for MODIFY COLUMN (t/38 verifies this
# by negative space: it does not probe it). The driver must therefore not
# emit a guard even when the capability is true, because the parser would
# reject it.

my $retype = diff_with_storage(
  model(tables => $base_tables, columns => { user => [
    { column_name => 'id',   data_type => 'UUID' },
    { column_name => 'rank', data_type => 'Int32' }
  ] }),
  model(tables => $base_tables, columns => { user => [
    { column_name => 'id',   data_type => 'UUID' },
    { column_name => 'rank', data_type => 'Int64' }
  ] }),
  $mock,
);
like $retype->as_sql,
  qr/ALTER TABLE `user` MODIFY COLUMN `rank` Int64/,
  'MODIFY COLUMN renders correctly when the capability is on';
unlike $retype->as_sql,
  qr/MODIFY COLUMN IF/,
  '  ... and never carries a MODIFY COLUMN IF [NOT] EXISTS guard, because '
. 'ClickHouse does not parse one (t/38 verified by negative space)';

# --- 5. without storage -> legacy bare behavior -----------------------------
# The helper returns 0 when storage is absent. The unguarded shape is what
# t/40 and t/41 already pin against a diff with no storage arg; this guards
# against accidental drift, on the same schema and the same diff.

my $guarded_first = diff_with_storage(
  model(),
  model(tables => $tables, columns => $columns),
  $mock,
)->as_sql;

my $bare_first = diff_no_storage(
  model(),
  model(tables => $tables, columns => $columns),
)->as_sql;

# The two diffs target the same model; the only thing that differs is whether
# storage was passed through. Storage gives IF NOT EXISTS / IF EXISTS; no
# storage does not.
like   $guarded_first, qr/CREATE TABLE IF NOT EXISTS/, 'capability on: CREATE IF NOT EXISTS';
unlike $bare_first,    qr/CREATE TABLE IF NOT EXISTS/, 'no storage: CREATE stays bare';
like   $guarded_first, qr/`id` UUID/,                  '  ... the table body is the same either way';
unlike $bare_first,    qr/IF EXISTS/,                 'no storage: no IF EXISTS anywhere';

my $guarded_drop = diff_with_storage(
  model(tables => $tables, columns => $columns), model(), $mock,
)->as_sql;
my $bare_drop = diff_no_storage(
  model(tables => $tables, columns => $columns), model(),
)->as_sql;
like   $guarded_drop, qr/DROP TABLE IF EXISTS/, 'capability on: DROP IF EXISTS';
unlike $bare_drop,    qr/IF EXISTS/,            'no storage: DROP stays bare';

# --- 6. Emit honours the flag directly --------------------------------------
# The diff path above routes through these helpers; this fixes the contract
# those helpers expose. Both `if_exists` and `if_not_exists` produce the
# exact string the diff relies on.

is create_table(
    name          => 'event',
    columns       => [ column_def(name => 'id', type => 'UUID') ],
    clauses       => [ DBIO::ClickHouse::DDL::Emit::engine_clause('MergeTree'),
                       DBIO::ClickHouse::DDL::Emit::order_by_clause('id') ],
    if_not_exists => 1,
  ),
  "CREATE TABLE IF NOT EXISTS `event` (\n  `id` UUID\n)\n"
. "ENGINE = MergeTree\nORDER BY (`id`);",
  'create_table(if_not_exists => 1) emits IF NOT EXISTS';

is drop_table(name => 'event', if_exists => 1),
  'DROP TABLE IF EXISTS `event`;',
  'drop_table(if_exists => 1) emits IF EXISTS';

is drop_table(name => 'event'),
  'DROP TABLE `event`;',
  'drop_table without the flag stays bare (default)';

is alter_table_add_column(
    table         => 'user',
    definition    => column_def(name => 'email', type => 'Nullable(String)'),
    if_not_exists => 1,
  ),
  'ALTER TABLE `user` ADD COLUMN IF NOT EXISTS `email` Nullable(String);',
  'alter_table_add_column(if_not_exists => 1) emits IF NOT EXISTS';

is alter_table_drop_column(table => 'user', name => 'legacy', if_exists => 1),
  'ALTER TABLE `user` DROP COLUMN IF EXISTS `legacy`;',
  'alter_table_drop_column(if_exists => 1) emits IF EXISTS';

is alter_table_add_index(
    table         => 'metric',
    definition    => index_def({ index_name => 'idx', expr => 'score',
                                 type_full  => 'minmax', granularity => 4 }),
    if_not_exists => 1,
  ),
  'ALTER TABLE `metric` ADD INDEX IF NOT EXISTS `idx` score TYPE minmax GRANULARITY 4;',
  'alter_table_add_index(if_not_exists => 1) emits IF NOT EXISTS';

is alter_table_drop_index(table => 'metric', name => 'idx', if_exists => 1),
  'ALTER TABLE `metric` DROP INDEX IF EXISTS `idx`;',
  'alter_table_drop_index(if_exists => 1) emits IF EXISTS';

# MODIFY COLUMN deliberately does NOT accept the flag -- see comments in Emit.
eval { alter_table_modify_column(
  table      => 'user',
  definition => column_def(name => 'rank', type => 'Int64'),
  if_exists  => 1,
) };
like $@, qr/does not accept if_exists/,
  'alter_table_modify_column croaks on if_exists (no MODIFY COLUMN guard '
. 'in ClickHouse; passing the flag is a contract error, not a no-op)';

done_testing;
