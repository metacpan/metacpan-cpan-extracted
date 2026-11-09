use strict;
use warnings;
use Test::More;

# t/20-introspect.t — DBIO::ClickHouse::Introspect against a live ClickHouse
# server, reached over the MySQL wire protocol.
#
# ClickHouse has NO embedded / in-memory mode, so unlike the SQLite and DuckDB
# suites this cannot run unattended: it needs a real server and is gated on
# DBIO_TEST_CLICKHOUSE_DSN. Without it the file skips cleanly — the offline
# contract for the same code is t/21-introspect-contract.t, which covers the
# normalization without a server.
#
# What this file is for is the half the contract test cannot reach: whether the
# system.* catalog actually reports what we assume it reports. Every assertion
# below is an assumption about the server, not about our parsing.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::Introspect;

# no_deploy: this file introspects a table it writes by hand, so the fixture
# would only be noise in the model -- and an empty database makes a failure
# here unambiguous.
my $schema = DBIO::ClickHouse::Test->init_schema(no_deploy => 1);
my $dbh    = $schema->storage->dbh;

my $table = 'dbio_introspect';

# `derived` is MATERIALIZED over `tags` and NOT over `title`, which would read
# better and does not work: a column that carries a DEFAULT of its own is not
# visible to another column's default expression. The server rejects
# `MATERIALIZED length(`title`)` outright --
#
#   Code: 47. Unknown identifier: title; there are columns: generateUUIDv4(), ...
#   While processing _CAST(length(title) AS derived_tmp_alter..., 'UInt8')
#   AS derived: default expression and column type are incompatible.
#
# -- even though `title` is declared three lines above it. ClickHouse validates
# all the default expressions of a CREATE TABLE as one expression list, in which
# every defaulted column is an ALIAS rather than an input, so only the plain
# columns can be referenced. `tags` is one; `title` (String DEFAULT 'untitled')
# is not.
$dbh->do(qq{
  CREATE TABLE `$table` (
    `id`      UUID DEFAULT generateUUIDv4(),
    `ts`      DateTime64(3),
    `name`    LowCardinality(Nullable(String)),
    `score`   Decimal(10, 2),
    `code`    FixedString(3),
    `state`   Enum8('draft' = 1, 'live' = 2),
    `title`   String DEFAULT 'untitled',
    `tags`    Array(String),
    `derived` UInt8 MATERIALIZED length(`tags`),
    INDEX `${table}_score_minmax` `score` TYPE minmax GRANULARITY 4
  )
  ENGINE = MergeTree
  PARTITION BY toYYYYMM(`ts`)
  PRIMARY KEY (`ts`)
  ORDER BY (`ts`, `id`)
});

my $intro = DBIO::ClickHouse::Introspect->new(dbh => $dbh);
my $model = $intro->model;

is ref $model, 'HASH', 'model is a hashref';
ok exists $model->{tables}{$table}, 'table introspected from system.tables';

my $entry = $model->{tables}{$table};
is $entry->{kind}, 'table', 'MergeTree engine reports as a table';
is $entry->{engine}, 'MergeTree', 'engine captured';
is $entry->{partition_key}, 'toYYYYMM(ts)', 'partition key captured';
is_deeply $entry->{sorting_key_entries}, [qw/ts id/], 'sorting key split into entries';
is_deeply $entry->{primary_key_entries}, ['ts'],
  'a declared PRIMARY KEY prefix is reported separately from the sorting key';

is_deeply $intro->table_columns($table),
  [qw/id ts name score code state title tags derived/], 'columns in declaration order';

# engine_full is the only place a parameterized engine's arguments survive --
# system.tables.engine drops them -- and it is also where the server writes its
# own SETTINGS defaults, which is why the diff compares engine_expression and
# not this.
like $entry->{engine_full}, qr/\AMergeTree\b/,
  'engine_full is readable over the MySQL wire and starts with the engine';
like $entry->{engine_full}, qr/SETTINGS/,
  '... and carries the server-side SETTINGS the diff deliberately ignores';

is_deeply $intro->table_pk_info($table), ['ts'], 'primary key from the MergeTree key';
is_deeply $intro->table_uniq_info($table), [], 'no unique constraints';
is_deeply $intro->table_fk_info($table),   [], 'no foreign keys';

# The type normalization itself is asserted offline in t/21-introspect-contract.t;
# what matters here is that the server hands back the type strings that test
# assumes -- above all that LowCardinality/Nullable survive as written and that
# Enum8 comes back with its members.
my $info = $intro->table_columns_info($table);

is $info->{id}{data_type}, 'uuid', 'UUID column';
ok $info->{id}{is_auto_increment}, 'DEFAULT generateUUIDv4() maps to is_auto_increment';
is $info->{ts}{data_type}, 'datetime', 'DateTime64(3) column';
is $info->{name}{data_type}, 'text', 'LowCardinality(Nullable(String)) column';
is $info->{name}{is_nullable}, 1, 'and it is nullable';
ok $info->{name}{extra}{low_cardinality}, 'and low-cardinality';
is_deeply $info->{score}{size}, [10, 2], 'Decimal precision/scale';
is $info->{code}{size}, 3, 'FixedString length';
is_deeply $info->{state}{extra}{list}, [qw/draft live/], 'Enum8 members';
is $info->{title}{default_value}, 'untitled', 'string default unquoted';
is $info->{tags}{data_type}, 'text[]', 'Array(String) column';

# system.columns.default_kind is what tells a computed column from a plain
# DEFAULT. Rendering a MATERIALIZED column back as DEFAULT would turn a derived
# value into a stored one, so the introspector keeps the kind out of
# default_value and in extra -- which is only correct if the server reports it.
is $info->{derived}{extra}{default_kind}, 'MATERIALIZED',
  'system.columns reports default_kind, so a computed column is not mistaken '
. 'for a plain DEFAULT';
like $info->{derived}{extra}{default_expression}, qr/length\(/,
  '... together with the expression it is computed from';
ok !exists $info->{derived}{default_value},
  '... and it is kept out of default_value, where a redeploy would flatten it';

# is_in_sorting_key is the column-level view of the MergeTree key. It is the
# only place system.columns says anything about keys at all -- there is no
# primary-key constraint to read.
{
  my %in_key = map { $_->{column_name} => $_->{is_in_sorting_key} }
    @{ $model->{columns}{$table} };

  is $in_key{ts}, 1, 'system.columns marks a sorting-key column';
  is $in_key{id}, 1, '... every one of them';
  is $in_key{name}, 0, '... and only them';
}

my $skipping = $model->{data_skipping_indexes}{$table} || {};
my $index    = $skipping->{"${table}_score_minmax"};
ok $index, 'data-skipping index read from system.data_skipping_indices';
is $index->{type}, 'minmax', 'skipping index type';
is $index->{granularity}, 4, 'skipping index granularity';

my ($stmt) = $intro->result_class_extra_statements($table);
is $stmt->[0], 'clickhouse_table', 'clickhouse_table statement emitted';
is $stmt->[1]{engine}, 'MergeTree', 'engine restated';
is_deeply $stmt->[1]{order_by}, [qw/ts id/], 'order_by restated';
is $stmt->[1]{partition_by}, 'toYYYYMM(ts)', 'partition_by restated';

# --- the empty sorting key --------------------------------------------------
#
# DBIO::ClickHouse::DDL renders a source with no primary key as
# ORDER BY tuple(). The introspector splits sorting_key on top-level commas, so
# everything downstream depends on the server reporting "no sorting key" as the
# EMPTY STRING rather than as the literal tuple(): a one-entry key called
# "tuple()" would make Diff::Table demand a rebuild that can never converge,
# because redeploying would produce the empty string again.

{
  my $bare = 'dbio_introspect_bare';
  $dbh->do(qq{
    CREATE TABLE `$bare` (`foo` Int32, `bar` String)
    ENGINE = MergeTree
    ORDER BY tuple()
  });

  my $bare_model = DBIO::ClickHouse::Introspect->new(dbh => $dbh)->model;
  my $bare_entry = $bare_model->{tables}{$bare};

  ok $bare_entry, 'the keyless table is in the model';
  is $bare_entry->{sorting_key}, '',
    'ORDER BY tuple() reports back as an empty sorting_key, not as tuple()';
  is_deeply $bare_entry->{sorting_key_entries}, [], '... so it splits to no entries';
  is_deeply $bare_entry->{primary_key_entries}, [],
    '... and the primary key mirrors it rather than inventing one';
  is_deeply(DBIO::ClickHouse::Introspect->new(dbh => $dbh)->table_pk_info($bare), [],
    '... which the contract reports as "no primary key"');
}

done_testing;
