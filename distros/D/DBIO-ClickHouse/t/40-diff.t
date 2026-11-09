use strict;
use warnings;
use Test::More;
use Test::Exception;

# t/40-diff.t — DBIO::ClickHouse::Diff over hand-built models. Offline: no DBD,
# no DSN, no server.
#
# The models below are shaped exactly like DBIO::ClickHouse::Introspect->model,
# because that is the only supported input: both sides of a real diff are
# introspected from a server, so data_type holds the NATIVE ClickHouse type
# string. Every assertion here is about ClickHouse intent rather than the shape
# of the generated string:
#
#   1. A table only in the target is created WHOLE — a ClickHouse table cannot
#      be built up with ADD COLUMN, it needs ENGINE and ORDER BY at CREATE time.
#   2. A type change is a MODIFY COLUMN, not a rebuild. That is the whole
#      reason this driver can diff at all.
#   3. A change to the sorting key / partition key / engine THROWS. Those are
#      immutable in ClickHouse, and both alternatives are worse than an error:
#      DROP+CREATE deletes the data, emitting nothing reports a success that
#      did not happen.
#   4. The known non-round-trip-safe spots (comments, codecs, MATERIALIZED
#      columns) resolve to a visible operation or to no operation — never to a
#      silent failure and never to a phantom that cannot converge.

use DBIO::ClickHouse::DDL;
use DBIO::ClickHouse::Diff;
use DBIO::ClickHouse::Diff::Table;

# --- model builders ----------------------------------------------------------

sub table_info {
  my (%a) = @_;
  my @sorting = @{ $a{order_by} // ['id'] };
  return {
    table_name            => $a{name},
    kind                  => $a{kind} // 'table',
    engine                => 'MergeTree',
    engine_expression     => $a{engine} // 'MergeTree',
    sorting_key           => join(', ', @sorting),
    sorting_key_entries   => \@sorting,
    primary_key           => join(', ', @{ $a{primary_key} // \@sorting }),
    primary_key_entries   => ($a{primary_key} // \@sorting),
    primary_key_columns   => [ grep { /\A\w+\z/ } @sorting ],
    partition_key         => $a{partition_by} // '',
    partition_key_entries => ($a{partition_by} ? [ $a{partition_by} ] : []),
    comment               => $a{comment}
  };
}

sub column {
  my ($name, $type, %a) = @_;
  return { column_name => $name, data_type => $type, %a };
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

# --- 1. a brand-new table is created whole -----------------------------------

my $event_target = model(
  tables  => { event => table_info(
    name => 'event', order_by => ['ts', 'id'], primary_key => ['ts'],
    partition_by => 'toYYYYMM(ts)'
  ) },
  columns => { event => [
    column('id',    'UUID',           default_value => 'generateUUIDv4()'),
    column('ts',    'DateTime64(3)'),
    column('title', 'String',         default_value => q{'untitled'}),
    column('score', 'Nullable(Decimal(10, 2))')
  ] }
);

my $fresh = diff_of(model(), $event_target);

ok $fresh->has_changes, 'empty source diffs against a schema';

my $create = $fresh->as_sql;

like $create, qr/CREATE TABLE `event`/, 'CREATE TABLE emitted for the new table';
like $create, qr/ENGINE = MergeTree/,   'engine is explicit — ClickHouse has no default';
like $create, qr/ORDER BY \(`ts`, `id`\)/, 'sorting key is explicit and quoted per column';
like $create, qr/PARTITION BY toYYYYMM\(ts\)/,
  'partition key is emitted verbatim as an expression, not quoted as an identifier';
like $create, qr/PRIMARY KEY \(`ts`\)/,
  'a PRIMARY KEY prefix narrower than the sorting key is restated';
like $create, qr/`title` String DEFAULT 'untitled'/,
  'the raw default expression from the model is emitted verbatim';
like $create, qr/`score` Nullable\(Decimal\(10, 2\)\)/,
  'nullability rides in the type, not in a NOT NULL constraint';
unlike $create, qr/\bNOT NULL\b/, 'no NOT NULL constraint is ever emitted';
unlike $create, qr/SETTINGS/,
  'SETTINGS is not written back — engine_full reports the server defaults';

# --- 1b. declared settings reach the create op (karr k30) --------------------
# The model's engine_full is the server's defaults and is never rendered; only
# what the schema declares (declared_settings) goes into the CREATE TABLE, in
# the shape the install DDL uses, after ORDER BY.

my $with_settings = DBIO::ClickHouse::Diff->new(
  source            => model(),
  target            => $event_target,
  declared_settings => { event => { index_granularity => 1024, ttl_only_drop_parts => 1 } },
);
like $with_settings->as_sql,
  qr/ORDER BY \(`ts`, `id`\)\nSETTINGS index_granularity = 1024, ttl_only_drop_parts = 1;\z/,
  'a created table gets the declared SETTINGS after ORDER BY';

my $other_table = DBIO::ClickHouse::Diff->new(
  source            => model(),
  target            => $event_target,
  declared_settings => { unrelated => { index_granularity => 1024 } },
);
unlike $other_table->as_sql, qr/SETTINGS/,
  'settings declared for another table do not leak into this one';

my $existing = DBIO::ClickHouse::Diff->new(
  source            => $event_target,
  target            => $event_target,
  declared_settings => { event => { index_granularity => 1024 } },
);
ok !$existing->has_changes,
  'a table that already exists is not compared on settings';

# All columns must be in the one CREATE TABLE: ClickHouse cannot add them
# afterwards to a table that does not exist yet.
unlike $create, qr/ADD COLUMN/, 'a new table gets no follow-up ADD COLUMN';
like $fresh->summary, qr/\+ table: event/, 'summary names the created table';

# The PRIMARY KEY clause is redundant when it equals the sorting key.
my $plain = diff_of(model(), model(
  tables  => { t => table_info(name => 't', order_by => ['id']) },
  columns => { t => [ column('id', 'UUID') ] }
))->as_sql;
unlike $plain, qr/PRIMARY KEY/,
  'no PRIMARY KEY clause when it is just the sorting key restated';
like $plain, qr/ORDER BY \(`id`\)/, 'single-column sorting key still uses the tuple form';

# --- 2. an identical model produces nothing ----------------------------------

ok !diff_of($event_target, $event_target)->has_changes,
  'a model diffed against itself is clean (idempotent redeploy)';

# --- 3. column-level changes -------------------------------------------------

my $base_tables  = { user => table_info(name => 'user', order_by => ['id']) };
my $base_columns = { user => [ column('id', 'UUID'), column('name', 'String') ] };

# added column
my $added = diff_of(
  model(tables => $base_tables, columns => $base_columns),
  model(tables => $base_tables, columns => { user => [
    @{ $base_columns->{user} }, column('email', 'Nullable(String)')
  ] })
);
is scalar @{ $added->operations }, 1, 'one operation for one added column';
like $added->as_sql, qr/\AALTER TABLE `user` ADD COLUMN `email` Nullable\(String\);\z/,
  'added column is an ALTER TABLE ADD COLUMN';
like $added->summary, qr/\+column: user\.email/, 'summary names the added column';

# removed column
my $removed = diff_of(
  model(tables => $base_tables, columns => { user => [
    @{ $base_columns->{user} }, column('legacy', 'String')
  ] }),
  model(tables => $base_tables, columns => $base_columns)
);
like $removed->as_sql, qr/\AALTER TABLE `user` DROP COLUMN `legacy`;\z/,
  'removed column is an ALTER TABLE DROP COLUMN';

# type change -> MODIFY COLUMN (the reason this driver can diff in place at all)
my $retyped = diff_of(
  model(tables => $base_tables, columns => { user => [
    column('id', 'UUID'), column('rank', 'Int32')
  ] }),
  model(tables => $base_tables, columns => { user => [
    column('id', 'UUID'), column('rank', 'Int64')
  ] })
);
is scalar @{ $retyped->operations }, 1, 'a type change is a single operation';
like $retyped->as_sql, qr/\AALTER TABLE `user` MODIFY COLUMN `rank` Int64;\z/,
  'type change is MODIFY COLUMN — not a drop and re-add, which would lose the data';
like $retyped->summary, qr/~column: user\.rank \(Int64\)/, 'summary marks it as a change';

# a nullability change is a type change here, and exactly one statement
my $nullable = diff_of(
  model(tables => $base_tables, columns => { user => [ column('bio', 'String') ] }),
  model(tables => $base_tables, columns => { user => [ column('bio', 'Nullable(String)') ] })
);
is scalar @{ $nullable->operations }, 1,
  'nullability change is one MODIFY COLUMN, not a separate SET/DROP NOT NULL';
like $nullable->as_sql, qr/MODIFY COLUMN `bio` Nullable\(String\)/,
  'nullability rides in the type';

# whitespace in a type string is not a change; letter case IS
ok !diff_of(
  model(tables => $base_tables, columns => { user => [ column('n', 'Decimal(10,  2)') ] }),
  model(tables => $base_tables, columns => { user => [ column('n', 'Decimal(10, 2)') ] })
)->has_changes, 'type comparison collapses whitespace';

ok diff_of(
  model(tables => $base_tables, columns => { user => [
    column('state', q{Enum8('draft' = 1)}) ] }),
  model(tables => $base_tables, columns => { user => [
    column('state', q{Enum8('Draft' = 1)}) ] })
)->has_changes,
  'type comparison is case-preserving — an enum member rename is a real change';

# --- 4. the rebuild policy ---------------------------------------------------

my $key_changed = diff_of(
  model(
    tables  => { event => table_info(name => 'event', order_by => ['ts', 'id']) },
    columns => { event => [ column('ts', 'DateTime64(3)'), column('id', 'UUID') ] }
  ),
  model(
    tables  => { event => table_info(name => 'event', order_by => ['ts', 'user_id', 'id']) },
    columns => { event => [ column('ts', 'DateTime64(3)'), column('id', 'UUID') ] }
  )
);

throws_ok { $key_changed->operations }
  qr/cannot be upgraded in place/,
  'a changed sorting key throws instead of silently doing nothing';

# The check must fire from every public entry point, not just operations().
throws_ok { $key_changed->has_changes } qr/sorting key \(ORDER BY\)/,
  'has_changes cannot route around the rebuild policy';
throws_ok { $key_changed->as_sql }  qr/cannot be upgraded in place/, 'as_sql either';
throws_ok { $key_changed->summary } qr/cannot be upgraded in place/, 'summary either';

my $error = do { local $@; eval { $key_changed->operations }; "$@" };
like $error, qr/EXCHANGE TABLES `event_new` AND `event`/,
  'the message contains a runnable rename, correctly quoted as one identifier';
like $error, qr/INSERT INTO `event_new` SELECT \* FROM `event`/,
  'and the copy statement';
like $error, qr/ts, id/,     'and the old key';
like $error, qr/ts, user_id, id/, 'and the new key';
unlike $error, qr/DROP TABLE `event`;/,
  'the instructions never tell you to drop the live table';

# Nothing may be emitted for such a table — not even a silent DROP/CREATE pair.
unlike do { local $@; eval { $key_changed->as_sql } // '' }, qr/DROP TABLE/,
  'no drop-and-recreate is produced';

for my $case (
  [ 'engine',                 { engine       => 'ReplacingMergeTree(version)' }, qr/engine/ ],
  [ 'partition key',          { partition_by => 'toYYYYMM(ts)' },  qr/partition key/ ],
  [ 'primary key prefix',     { primary_key  => ['id'] },          qr/primary key/ ]
) {
  my ($label, $override, $pattern) = @$case;
  my $source = model(tables => { t => table_info(name => 't', order_by => ['ts', 'id']) });
  my $target = model(
    tables => { t => table_info(name => 't', order_by => ['ts', 'id'], %$override) });
  throws_ok { diff_of($source, $target)->operations } $pattern,
    "a changed $label throws too — it is immutable for the same reason";
}

# Desired-state contract: a property the target does not prescribe is not
# compared, so a partially-specified target model never trips the policy.
lives_ok {
  DBIO::ClickHouse::Diff::Table->check_rebuild_required(
    { t => table_info(name => 't', order_by => ['ts', 'id']) },
    { t => { table_name => 't' } }
  )
} 'an unprescribed target property is not compared';

# SETTINGS live in engine_full, which the server fills with its own defaults;
# comparing it would throw on every table. engine_expression is compared instead.
lives_ok {
  my $source = model(tables => { t => table_info(name => 't') });
  my $target = model(tables => { t => table_info(name => 't') });
  $source->{tables}{t}{engine_full} = 'MergeTree ORDER BY id SETTINGS index_granularity = 8192';
  $target->{tables}{t}{engine_full} = 'MergeTree ORDER BY id';
  diff_of($source, $target)->operations;
} 'server-supplied SETTINGS in engine_full do not trip the rebuild policy';

# --- 5. dropped tables -------------------------------------------------------

my $dropped = diff_of(
  model(
    tables  => { leftover => table_info(name => 'leftover') },
    columns => { leftover => [ column('id', 'UUID') ] }
  ),
  model()
);
like $dropped->as_sql, qr/\ADROP TABLE `leftover`;\z/,
  'a table absent from the target is dropped';
unlike $dropped->as_sql, qr/DROP COLUMN/,
  'and its columns are not dropped one by one first';

# --- 6. views are out of scope ----------------------------------------------
# A view reaching Diff::Table would be rendered as a CREATE TABLE — flatly
# wrong; views have their own operations (Diff::View, t/47).

my $with_view = model(
  tables  => { v => table_info(name => 'v', kind => 'view', order_by => []) },
  columns => { v => [ column('id', 'UUID') ] }
);
ok !diff_of(model(), $with_view)->has_changes,
  'a view in the target produces no operation';
ok !diff_of($with_view, model())->has_changes,
  'and a view in the source is not dropped either';
ok !diff_of(
  $with_view,
  model(
    tables  => { v => table_info(name => 'v', kind => 'view', order_by => []) },
    columns => { v => [ column('id', 'String') ] }
  )
)->has_changes, 'and a view column is never ALTERed';

# --- 7. round trip, and the spots that cannot round trip ---------------------

# karr k11, fixed on the DDL side: a column declared with the native spelling
# 'Date' now deploys as Date, so a live Date column and a schema asking for
# Date agree and there is nothing to do. The desired type is asked of
# DBIO::ClickHouse::DDL rather than hardcoded on purpose — this assertion is
# what fails if the DDL layer ever starts widening a native name again, which
# is what used to make every live Date column a change on every redeploy.
my $desired_date =
  DBIO::ClickHouse::DDL::_clickhouse_column_type({ data_type => 'Date' });
ok !diff_of(
  model(tables => $base_tables, columns => { user => [ column('born', 'Date') ] }),
  model(tables => $base_tables, columns => { user => [ column('born', $desired_date) ] })
)->has_changes,
  'karr k11: a live Date against a schema declaring Date is not a change';

# A genuine widening is still one visible MODIFY COLUMN that converges after a
# single apply: Date and Date32 are two different types, not two spellings of
# the same one, so the diff must show the change rather than collapse it.
my $widened = diff_of(
  model(tables => $base_tables, columns => { user => [ column('born', 'Date') ] }),
  model(tables => $base_tables, columns => { user => [ column('born', 'Date32') ] })
);
is scalar @{ $widened->operations }, 1,
  'Date vs Date32 is one visible operation, not a silent skip';
like $widened->as_sql, qr/MODIFY COLUMN `born` Date32/, 'and it names the widened type';
ok !diff_of(
  model(tables => $base_tables, columns => { user => [ column('born', 'Date32') ] }),
  model(tables => $base_tables, columns => { user => [ column('born', 'Date32') ] })
)->has_changes, 'and it converges after one apply rather than reappearing forever';

# Comments and compression codecs are read by the introspector but can never be
# prescribed by the desired side. Comparing them would strip them on the first
# upgrade of every live database.
ok !diff_of(
  model(tables => $base_tables, columns => { user => [
    column('id', 'UUID', comment => 'the key', compression_codec => 'CODEC(ZSTD(3))') ] }),
  model(tables => $base_tables, columns => { user => [ column('id', 'UUID') ] })
)->has_changes, 'live comments and codecs are left alone, not diffed away';

# A live MATERIALIZED column is computed, not stored as written. This driver
# cannot render that clause from a desired-state model, so a bare MODIFY would
# strip the expression and silently turn it into an empty column.
ok !diff_of(
  model(tables => $base_tables, columns => { user => [
    column('slug', 'String', default_kind => 'MATERIALIZED',
           default_value => 'lower(name)') ] }),
  model(tables => $base_tables, columns => { user => [ column('slug', 'Int64') ] })
)->has_changes, 'an unmanaged MATERIALIZED column is left alone, not flattened';

# A MATERIALIZED column in the TARGET is rendered as itself, not as a DEFAULT —
# emitting DEFAULT there would change what the column means.
my $materialized = diff_of(model(), model(
  tables  => { t => table_info(name => 't') },
  columns => { t => [ column('slug', 'String', default_kind => 'MATERIALIZED',
                             default_value => 'lower(name)') ] }
))->as_sql;
like $materialized, qr/`slug` String MATERIALIZED lower\(name\)/,
  'MATERIALIZED is emitted as MATERIALIZED';
unlike $materialized, qr/DEFAULT lower/, 'and never downgraded to a DEFAULT';

# --- views declared by the schema are created (karr k31) -------------------
# The SELECT to create comes from the schema (declared_views). A view only the
# schema has is a CREATE VIEW, after the table it may select from. Dropping and
# replacing views, which compare definitions, is t/47-diff-view.t.

my $v_tables = { event => table_info(name => 'event') };
my $v_cols   = { event => [ column('id', 'UUID') ] };
my $views    = { v_recent => 'SELECT id FROM event WHERE id != 0' };

my $new_view = DBIO::ClickHouse::Diff->new(
  source         => model(tables => $v_tables, columns => $v_cols),
  target         => model(tables => $v_tables, columns => $v_cols),
  declared_views => $views,
);
ok $new_view->has_changes, 'a declared view missing live is a change';
is $new_view->as_sql,
  'CREATE VIEW `v_recent` AS SELECT id FROM event WHERE id != 0;',
  'it renders as CREATE VIEW from the declared definition (same renderer as install)';
like $new_view->summary, qr/\+ view: v_recent/, 'summary names the created view';

my $with_table = DBIO::ClickHouse::Diff->new(
  source         => model(),
  target         => model(tables => $v_tables, columns => $v_cols),
  declared_views => $views,
);
like $with_table->as_sql,
  qr/CREATE TABLE `event`.*CREATE VIEW `v_recent`/s,
  'a view comes after the tables it may depend on';

my $live_view = model(
  tables  => { %$v_tables, v_recent => table_info(name => 'v_recent', kind => 'view') },
  columns => $v_cols,
);
ok !DBIO::ClickHouse::Diff->new(
  source => $live_view, target => model(tables => $v_tables, columns => $v_cols),
  declared_views => $views,
)->has_changes, 'a view that exists live, its definition unknown, is not recreated';

ok !diff_of(model(tables => $v_tables, columns => $v_cols),
            model(tables => $v_tables, columns => $v_cols))->has_changes,
  'without declared_views there is no view operation';

done_testing;
