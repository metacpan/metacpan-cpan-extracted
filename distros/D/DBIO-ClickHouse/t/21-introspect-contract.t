use strict;
use warnings;
use Test::More;

# t/21-introspect-contract.t — the normalized DBIO::Introspect::Base contract
# implemented by DBIO::ClickHouse::Introspect, plus the pure parsers the
# system.* readers use. Offline: the model is injected directly, no ClickHouse
# server and no MySQL-wire DBD involved.
#
# The intent this locks down: introspection is the *inverse* of
# DBIO::ClickHouse::DDL. Every native type the DDL layer can emit must
# normalize back to the column_info that produced it, or the diff layer
# (which compares an introspected live model against an introspected
# desired model) reports a phantom change on every single run. That is why
# the bulk of this file is a round-trip assertion through
# DBIO::ClickHouse::DDL's own renderer rather than a table of expected
# strings: a change to either side breaks it.

use DBIO::ClickHouse::Introspect;
use DBIO::ClickHouse::Introspect::Tables;
use DBIO::ClickHouse::Introspect::Util;
use DBIO::ClickHouse::DDL;

package DBIO::ClickHouse::Introspect::Mock;
use base 'DBIO::ClickHouse::Introspect';
# No dbh: anything that reaches for the database in this file is a bug.
sub _build_model { die 'offline contract test must not query the server' }

package main;

sub ch_type { DBIO::ClickHouse::DDL::_clickhouse_column_type($_[0]) }

# ---------------------------------------------------------------------------
# The injected model. Shaped exactly as the system.* readers build it: raw
# ClickHouse type strings in data_type, raw default *expressions* in
# default_value, MergeTree metadata on the table rows.
# ---------------------------------------------------------------------------

# Column rows for the type-coverage table, in system.columns "position" order.
# native type => the rest of the row.
my @TYPE_COLUMNS = (
  [ id        => 'UUID',                            { default_kind => 'DEFAULT',
                                                      default_value => 'generateUUIDv4()' } ],
  [ name      => 'LowCardinality(Nullable(String))', {} ],
  [ tag       => 'LowCardinality(String)',          {} ],
  [ n8        => 'Int8',                            {} ],
  [ n64       => 'Int64',                           {} ],
  [ u32       => 'UInt32',                          {} ],
  [ score     => 'Decimal(10, 2)',                  {} ],
  [ big       => 'Nullable(Decimal(38, 9))',        {} ],
  [ code      => 'FixedString(3)',                  {} ],
  [ born      => 'Date32',                          {} ],
  [ ts        => 'DateTime64(3)',                   {} ],
  [ tsz       => "DateTime64(3, 'UTC')",            {} ],
  [ micro     => 'DateTime64(6)',                   {} ],
  [ berlin    => "DateTime64(3, 'Europe/Berlin')",  {} ],
  [ day       => 'Date',                            {} ],
  [ second    => 'DateTime',                        {} ],
  [ flag      => 'Bool',                            {} ],
  [ state     => q{Enum8('draft' = 1, 'live' = 2)}, {} ],
  [ odd       => q{Enum8('a' = 0, 'b' = 5)},        {} ],
  [ tags      => 'Array(String)',                   {} ],
  [ nested    => 'Array(Nullable(String))',         {} ],
  [ ratio     => 'Float64',                         {} ],
  [ addr      => 'IPv6',                            {} ],
  [ doc       => 'JSON',                            {} ],
  [ title     => 'String',      { default_kind => 'DEFAULT', default_value => q{'untitled'} } ],
  [ escaped   => 'String',      { default_kind => 'DEFAULT', default_value => q{'it\\'s'} } ],
  [ rank      => 'Int32',       { default_kind => 'DEFAULT', default_value => '0' } ],
  [ created   => 'DateTime64(3)', { default_kind => 'DEFAULT', default_value => 'now64(3)' } ],
  [ doubled   => 'Int32',       { default_kind => 'MATERIALIZED', default_value => 'rank * 2' } ],
);

my @types_rows;
{
  my $position = 0;
  for my $spec (@TYPE_COLUMNS) {
    my ($name, $type, $rest) = @$spec;
    push @types_rows, {
      column_name => $name,
      data_type   => $type,
      not_null    => DBIO::ClickHouse::Introspect::Util->normalize_type($type)->{is_nullable}
                     ? 0 : 1,
      default_kind  => $rest->{default_kind},
      default_value => $rest->{default_value},
      is_pk         => ($name eq 'id') ? 1 : 0,
      pk_position   => ($name eq 'id') ? 1 : undef,
      position      => ++$position,
      comment       => ($name eq 'name') ? 'display name' : undef,
    };
  }
}

my $MODEL = {
  tables => {
    types => {
      table_name          => 'types',
      database            => 'default',
      kind                => 'table',
      engine              => 'MergeTree',
      engine_full         => 'MergeTree ORDER BY (`id`) SETTINGS index_granularity = 8192',
      engine_expression   => 'MergeTree',
      sorting_key         => 'id',
      sorting_key_entries => ['id'],
      primary_key         => 'id',
      primary_key_entries => ['id'],
      primary_key_columns => ['id'],
      partition_key         => '',
      partition_key_entries => [],
      sampling_key        => '',
      comment             => undef,
    },
    event => {
      table_name          => 'event',
      database            => 'default',
      kind                => 'table',
      engine              => 'ReplacingMergeTree',
      engine_full         => 'ReplacingMergeTree(ver) PARTITION BY toYYYYMM(ts) '
                           . 'ORDER BY (`ts`, `id`) SETTINGS index_granularity = 8192',
      engine_expression   => 'ReplacingMergeTree(ver)',
      sorting_key         => 'ts, id',
      sorting_key_entries => [qw/ts id/],
      primary_key         => 'ts',
      primary_key_entries => ['ts'],
      primary_key_columns => ['ts'],
      partition_key         => 'toYYYYMM(ts)',
      partition_key_entries => ['toYYYYMM(ts)'],
      sampling_key        => '',
      comment             => 'append-only event log',
    },
    hashed => {
      table_name          => 'hashed',
      database            => 'default',
      kind                => 'table',
      engine              => 'MergeTree',
      engine_full         => 'MergeTree ORDER BY (cityHash64(`id`))',
      engine_expression   => 'MergeTree',
      sorting_key         => 'cityHash64(id)',
      sorting_key_entries => ['cityHash64(id)'],
      primary_key         => 'cityHash64(id)',
      primary_key_entries => ['cityHash64(id)'],
      primary_key_columns => [],
      partition_key         => '',
      partition_key_entries => [],
      sampling_key        => '',
      comment             => undef,
    },
    top_event => {
      table_name          => 'top_event',
      database            => 'default',
      kind                => 'view',
      engine              => 'View',
      engine_full         => 'View',
      engine_expression   => 'View',
      sorting_key         => '',
      sorting_key_entries => [],
      primary_key         => '',
      primary_key_entries => [],
      primary_key_columns => [],
      partition_key         => '',
      partition_key_entries => [],
      sampling_key        => '',
      comment             => undef,
    },
  },
  columns => {
    types => \@types_rows,
    event => [
      { column_name => 'ts', data_type => 'DateTime64(3)', not_null => 1,
        default_kind => undef, default_value => undef,
        is_pk => 1, pk_position => 1, position => 1, comment => undef },
      { column_name => 'id', data_type => 'UUID', not_null => 1,
        default_kind => undef, default_value => undef,
        is_pk => 0, pk_position => undef, position => 2, comment => undef },
      { column_name => 'ver', data_type => 'UInt64', not_null => 1,
        default_kind => undef, default_value => undef,
        is_pk => 0, pk_position => undef, position => 3, comment => undef },
    ],
    hashed => [
      { column_name => 'id', data_type => 'UUID', not_null => 1,
        default_kind => undef, default_value => undef,
        is_pk => 0, pk_position => undef, position => 1, comment => undef },
    ],
    top_event => [
      { column_name => 'id', data_type => 'UUID', not_null => 1,
        default_kind => undef, default_value => undef,
        is_pk => 0, pk_position => undef, position => 1, comment => undef },
    ],
  },
  data_skipping_indexes => {
    event => {
      event_ver_minmax => { index_name => 'event_ver_minmax', expr => 'ver',
                            type => 'minmax', type_full => 'minmax', granularity => 4 },
      event_id_set     => { index_name => 'event_id_set', expr => 'id',
                            type => 'set', type_full => 'set(100)', granularity => 1 },
    },
  },
  indexes      => {},
  foreign_keys => {},
};

my $intro = DBIO::ClickHouse::Introspect::Mock->new(model => $MODEL);

# ---------------------------------------------------------------------------
# Canonical contract inherited from DBIO::Introspect::Base
# ---------------------------------------------------------------------------

is_deeply $intro->table_keys, [qw/event hashed top_event types/], 'table_keys sorted';

is_deeply $intro->table_columns('event'), [qw/ts id ver/],
  'table_columns in system.columns position order, not alphabetical';

ok !$intro->table_is_view('event'),    'a MergeTree table is not a view';
ok  $intro->table_is_view('top_event'), 'the View engine makes it a view';

# The MergeTree key stands in for a primary key; PRIMARY KEY (ts) is a prefix
# of ORDER BY (ts, id), so only ts is the primary key.
is_deeply $intro->table_pk_info('event'), ['ts'],
  'primary key comes from the MergeTree key prefix, not from a constraint';
is_deeply $intro->table_pk_info('hashed'), [],
  'an expression sorting key yields no primary-key columns — it names no column';

# ---------------------------------------------------------------------------
# The two contract methods may never disagree about one column
# (core k126, this repo's k19)
#
# DBIO::Introspect::Base::table_columns_info folds the primary key into
# is_nullable — `($col->{not_null} || $col->{is_pk}) ? 0 : 1` — because most
# engines report the NOT NULL *attribute* separately from the key
# *constraint*, so a key column arrives with not_null = 0 and the base used to
# call the primary key of every generated result class nullable while
# table_pk_info, reading is_pk off the same hashref, called it a key.
#
# This driver overrides table_columns_info and does not fold, because the fold
# has nothing to repair here: ClickHouse encodes nullability in the type
# (Nullable(T)), Introspect::Columns derives not_null from exactly that, and
# the override re-reads the same type string. The invariant holds anyway, for
# the server's own reason — a stock ClickHouse refuses a Nullable column in a
# MergeTree key at all (allow_nullable_key defaults to 0).
#
# Both loops are independent of which core is installed: the override never
# calls SUPER, so this is green against a pre-k126 core too.
# ---------------------------------------------------------------------------

for my $table (@{ $intro->table_keys }) {
  my $columns = $intro->table_columns_info($table);
  for my $name (@{ $intro->table_pk_info($table) }) {
    is $columns->{$name}{is_nullable}, 0,
      "$table.$name is named by table_pk_info and is never reported nullable";
  }
}

# The mechanism the invariant rests on, pinned so it cannot rot into a
# coincidence: is_nullable is the model's not_null and nothing else. Nothing in
# this driver can make the two disagree, so a key column could only come back
# nullable if the server really declared it Nullable.
for my $table (@{ $intro->table_keys }) {
  my $columns = $intro->table_columns_info($table);
  for my $col (@{ $intro->model->{columns}{$table} || [] }) {
    my $name = $col->{column_name};
    is $columns->{$name}{is_nullable}, ($col->{not_null} ? 0 : 1),
      "$table.$name: is_nullable is the complement of the model's not_null";
  }
}

# ---------------------------------------------------------------------------
# ClickHouse has no unique constraints and no foreign keys
# ---------------------------------------------------------------------------

is_deeply $intro->table_uniq_info('event'), [],
  'no unique constraints — a data-skipping index enforces nothing and must '
  . 'never be reported as one';
is_deeply $intro->table_fk_info('event'), [],
  'no foreign keys (ADR 0004)';

# Skipping indexes are their own model section, not the canonical `indexes` one.
is_deeply $MODEL->{indexes}, {}, 'canonical indexes section stays empty';
is $MODEL->{data_skipping_indexes}{event}{event_ver_minmax}{granularity}, 4,
  'skipping index keeps its granularity — an ALTER TABLE ADD INDEX needs it';
is $MODEL->{data_skipping_indexes}{event}{event_id_set}{type_full}, 'set(100)',
  'skipping index keeps its parameterized type';

# ---------------------------------------------------------------------------
# Type normalization: the inverse of DBIO::ClickHouse::DDL's type map
# ---------------------------------------------------------------------------

my $info = $intro->table_columns_info('types');

# -- nullability lives in the type, not in a column constraint --------------
is $info->{name}{is_nullable}, 1, 'Nullable(...) inside LowCardinality is unwrapped';
is $info->{tag}{is_nullable},  0, 'LowCardinality(String) is not nullable';
is $info->{n8}{is_nullable},   0, 'ClickHouse columns are NOT NULL by default';
is $info->{big}{is_nullable},  1, 'Nullable(Decimal(...)) is nullable';

# -- LowCardinality is a flag, never part of data_type ----------------------
is $info->{name}{data_type}, 'text', 'LowCardinality(Nullable(String)) -> text';
ok $info->{name}{extra}{low_cardinality}, 'low_cardinality captured in extra';
ok !exists $info->{n8}{extra}, 'no extra hash at all when there is nothing to say';

# -- integer widths, signed and unsigned ------------------------------------
is $info->{n8}{data_type},  'tinyint', 'Int8 -> tinyint';
is $info->{n64}{data_type}, 'bigint',  'Int64 -> bigint';
is $info->{u32}{data_type}, 'integer', 'UInt32 -> integer';
ok $info->{u32}{extra}{unsigned}, 'UInt32 sets the unsigned flag';
ok !$info->{n8}{extra}{unsigned}, 'Int8 does not';

# -- sizes: Decimal, FixedString, DateTime64 --------------------------------
is $info->{score}{data_type}, 'decimal',   'Decimal(P, S) -> decimal';
is_deeply $info->{score}{size}, [10, 2],   'Decimal precision/scale into size';
is_deeply $info->{big}{size},   [38, 9],   'Decimal size survives the Nullable wrapper';
is $info->{code}{data_type}, 'char',       'FixedString(N) -> char';
is $info->{code}{size}, 3,                 'FixedString length into size';
ok $info->{code}{extra}{fixed_string},
  'fixed_string stays opt-in, so a regenerated schema does not turn every '
  . 'char column into zero-byte-padded FixedString';
is $info->{ts}{data_type}, 'datetime',     'DateTime64(3) -> datetime';
is $info->{ts}{size}, 3,                   'DateTime64 precision into size';
is $info->{micro}{data_type}, 'DateTime64(6)',
  'a non-millisecond precision has no portable spelling and stays verbatim';
is $info->{micro}{size}, 6, 'verbatim DateTime64 still exposes its precision';

# -- timezone ---------------------------------------------------------------
is $info->{tsz}{data_type}, 'timestamptz', "DateTime64(3, 'UTC') -> timestamptz";
is $info->{tsz}{extra}{timezone}, 'UTC',   'timezone captured';
is $info->{berlin}{data_type}, "DateTime64(3, 'Europe/Berlin')",
  'a non-UTC zone has no portable spelling and stays verbatim';
is $info->{berlin}{extra}{timezone}, 'Europe/Berlin', 'non-UTC timezone still captured';

# -- the remaining scalar mappings ------------------------------------------
is $info->{born}{data_type},  'date',             'Date32 -> date';
is $info->{flag}{data_type},  'boolean',          'Bool -> boolean';
is $info->{id}{data_type},    'uuid',             'UUID -> uuid';
is $info->{ratio}{data_type}, 'double precision', 'Float64 -> double precision';
is $info->{addr}{data_type},  'IPv6',
  'an unmapped native type passes through verbatim in both directions';
is $info->{day}{data_type},    'Date',
  'the narrow Date is reported as itself, not normalized to the portable '
  . '"date" that renders back as Date32';
is $info->{second}{data_type}, 'DateTime', 'and the second-resolution DateTime';
is $info->{doc}{data_type},    'JSON',
  'the native JSON type survives — only the portable lowercase "json" is String';

# -- enums ------------------------------------------------------------------
is $info->{state}{data_type}, 'enum', 'a 1..N enum is the portable "enum"';
is_deeply $info->{state}{extra}{list}, [qw/draft live/],
  'enum members in declaration order';
is $info->{odd}{data_type}, q{Enum8('a' = 0, 'b' = 5)},
  'an enum numbered anything but 1..N cannot be expressed portably and '
  . 'stays verbatim rather than being silently renumbered';
is_deeply $info->{odd}{extra}{list}, [qw/a b/],
  'the member names are still exposed for readers that want them';

# -- arrays -----------------------------------------------------------------
is $info->{tags}{data_type}, 'text[]', 'Array(String) -> text[]';
is $info->{nested}{data_type}, 'Array(Nullable(String))',
  'a nullable element type cannot be rebuilt from "T[]" + is_nullable, so the '
  . 'whole type stays verbatim';

# ---------------------------------------------------------------------------
# Defaults: the inverse of DBIO::ClickHouse::DDL::_column_default
# ---------------------------------------------------------------------------

is $info->{title}{default_value}, 'untitled',
  'a quoted literal comes back as a plain scalar';
is $info->{escaped}{default_value}, "it's",
  'quote_string escaping is undone';

is ref $info->{rank}{default_value}, 'SCALAR',
  'a bare number is raw SQL, not a string — a plain scalar would re-render '
  . q{as DEFAULT '0'};
is ${ $info->{rank}{default_value} }, '0', 'raw numeric default kept verbatim';

is ref $info->{created}{default_value}, 'SCALAR', 'a function default is a literal ref';
is ${ $info->{created}{default_value} }, 'now64(3)', 'function default kept verbatim';

ok $info->{id}{is_auto_increment},
  'generateUUIDv4() on a UUID column maps back to is_auto_increment';
ok !exists $info->{id}{default_value},
  'and not to a default_value, which is what the DDL layer expects back';
ok !exists $info->{id}{retrieve_on_insert},
  'never retrieve_on_insert — ClickHouse has no RETURNING and no last_insert_id';

ok !exists $info->{doubled}{default_value},
  'a MATERIALIZED column has no DEFAULT; emitting one would change its semantics';
is $info->{doubled}{extra}{default_kind}, 'MATERIALIZED', 'kind recorded in extra';
is $info->{doubled}{extra}{default_expression}, 'rank * 2', 'expression recorded in extra';

ok !exists $info->{n8}{default_value}, 'no default when the column has none';

# ---------------------------------------------------------------------------
# Round trip: every normalized column must re-render to the native type it
# came from. This is the assertion the diff layer (ticket k6) depends on.
# ---------------------------------------------------------------------------

for my $spec (@TYPE_COLUMNS) {
  my ($name, $native) = @$spec;
  is ch_type($info->{$name}), $native, "round trip: $native";
}

# Decimal64(S) is the documented exception: it is a fixed-precision alias, so
# it normalizes to the canonical Decimal(18, S) it is equivalent to. A live
# server reports the canonical form anyway; this only bites when a server
# echoes the alias back.
my $alias = DBIO::ClickHouse::Introspect::Util->normalize_type('Decimal64(4)');
is_deeply $alias->{size}, [18, 4], 'Decimal64(S) resolves to its real precision';
is ch_type($alias), 'Decimal(18, 4)',
  'Decimal64(4) re-renders as the equivalent canonical Decimal(18, 4)';

# Bare Date / DateTime are reported truthfully AND round trip: the DDL layer
# treats an exact native spelling as a passthrough, so what the server calls
# 'Date' is redeployed as 'Date'. (karr k11: the DDL layer used to lowercase
# data_type before its type-map lookup, so 'Date' hit the date => Date32 entry
# and every live Date column showed up as a change on every redeploy.)
for my $native (qw(Date DateTime)) {
  is(DBIO::ClickHouse::Introspect::Util->normalize_type($native)->{data_type},
    $native, "bare $native is reported as-is");
  is ch_type({ data_type => $native }), $native, "and re-renders as $native";
}

# The portable lowercase spellings still widen — which is what makes the pair
# above a deliberate choice by the schema author rather than an accident.
is ch_type({ data_type => 'date' }),     'Date32',
  'the portable "date" still widens for range correctness';
is ch_type({ data_type => 'datetime' }), 'DateTime64(3)',
  'and the portable "datetime" for precision';

# ---------------------------------------------------------------------------
# Comments
# ---------------------------------------------------------------------------

is $intro->table_comment('event'), 'append-only event log', 'table comment';
is $intro->table_comment('types'), undef, 'no table comment';
is $intro->column_comment('types', 'name'), 'display name', 'column comment';
is $intro->column_comment('types', 'n8'),   undef, 'no column comment';

# view_definition returns early for a non-view, so it never reaches for a dbh.
is $intro->view_definition('event'), undef, 'view_definition is undef for a table';

# ---------------------------------------------------------------------------
# result_class_extra_statements: engine + MergeTree keys survive regeneration
# ---------------------------------------------------------------------------

my @stmts = $intro->result_class_extra_statements('event');
is scalar @stmts, 1, 'one clickhouse_table statement per table';
is $stmts[0][0], 'clickhouse_table', 'emitted through the Result component';

my $opts = $stmts[0][1];
is $opts->{engine}, 'ReplacingMergeTree(ver)',
  'the engine keeps its arguments — system.tables.engine drops them, '
  . 'engine_full is where they survive';
is_deeply $opts->{order_by}, [qw/ts id/], 'sorting key becomes order_by';
is $opts->{partition_by}, 'toYYYYMM(ts)', 'partition key is an expression, verbatim';
is_deeply $opts->{primary_key}, ['ts'],
  'primary_key emitted because it is a strict prefix of order_by';

my $types_opts = ($intro->result_class_extra_statements('types'))[0][1];
ok !exists $types_opts->{primary_key},
  'primary_key omitted when it merely mirrors the sorting key';
is $types_opts->{engine}, 'MergeTree', 'plain engine';

my $hashed_opts = ($intro->result_class_extra_statements('hashed'))[0][1];
is ref $hashed_opts->{order_by}[0], 'SCALAR',
  'an expression key entry is a SCALAR ref, or clickhouse_table would quote '
  . 'cityHash64(id) as an identifier';
is ${ $hashed_opts->{order_by}[0] }, 'cityHash64(id)', 'expression kept verbatim';

is_deeply [ $intro->result_class_extra_statements('top_event') ], [],
  'a view has no engine options to restate';

# ---------------------------------------------------------------------------
# The pure parsers the system.* readers rely on
# ---------------------------------------------------------------------------

is_deeply [ DBIO::ClickHouse::Introspect::Util->split_top_level('ts, id') ],
  [qw/ts id/], 'plain key list';
is_deeply [ DBIO::ClickHouse::Introspect::Util->split_top_level('toYYYYMM(ts), id') ],
  ['toYYYYMM(ts)', 'id'],
  'commas inside parentheses are not separators — a plain split would shred '
  . 'toStartOfInterval(ts, INTERVAL 1 DAY)';
is_deeply [ DBIO::ClickHouse::Introspect::Util->split_top_level(q{'a,b' = 1, 'c' = 2}) ],
  [q{'a,b' = 1}, q{'c' = 2}], 'commas inside string literals are not separators';
is_deeply [ DBIO::ClickHouse::Introspect::Util->split_top_level('') ], [],
  'ORDER BY tuple() reports an empty sorting key';

is(DBIO::ClickHouse::Introspect::Util->unquote_string(q{'plain'}), 'plain',
  'unquote a literal');
is(DBIO::ClickHouse::Introspect::Util->unquote_string(q{'a' || 'b'}), undef,
  'an expression made of literals is not a literal and must not be truncated');
is(DBIO::ClickHouse::Introspect::Util->unquote_string('now()'), undef,
  'a function call is not a literal');

is(DBIO::ClickHouse::Introspect::Tables::_kind('MergeTree'), 'table',
  'MergeTree is a table');
is(DBIO::ClickHouse::Introspect::Tables::_kind('View'), 'view',
  'View is a view');
is(DBIO::ClickHouse::Introspect::Tables::_kind('MaterializedView'), 'view',
  'MaterializedView is a view');

is(DBIO::ClickHouse::Introspect::Tables::_engine_expression(
     'ReplacingMergeTree',
     'ReplacingMergeTree(ver) ORDER BY (`ts`) SETTINGS index_granularity = 8192'
   ), 'ReplacingMergeTree(ver)',
  'engine arguments recovered from engine_full');
is(DBIO::ClickHouse::Introspect::Tables::_engine_expression(
     'MergeTree', 'MergeTree ORDER BY (`id`) SETTINGS index_granularity = 8192'
   ), 'MergeTree',
  'a plain engine does not pick up the trailing clauses');
is(DBIO::ClickHouse::Introspect::Tables::_engine_expression('Memory', undef), 'Memory',
  'falls back to the bare engine name when engine_full is unavailable');

done_testing;
