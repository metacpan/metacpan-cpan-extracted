use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# parse_create_table turns a SHOW CREATE TABLE string back into the
# structured shape schema_diff / format_create_table consume.

# Full DDL with every trailing clause.
{
    my $ddl = <<'DDL';
CREATE TABLE analytics.events
(
    `id` UInt64,
    `name` String DEFAULT 'anon',
    `ts` DateTime CODEC(DoubleDelta, LZ4),
    `payload` Nullable(String),
    `tags` Array(LowCardinality(String))
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(ts)
PRIMARY KEY id
ORDER BY (id, ts)
SAMPLE BY id
TTL ts + INTERVAL 90 DAY
SETTINGS index_granularity = 8192
DDL
    my $p = ClickHouse::Encoder->parse_create_table($ddl);
    is($p->{database}, 'analytics',          'database extracted');
    is($p->{table},    'events',             'table extracted');
    is($p->{engine},   'MergeTree',          'engine extracted');
    is($p->{partition_by}, 'toYYYYMM(ts)',   'partition_by extracted');
    is($p->{primary_key},  'id',             'primary_key extracted');
    is($p->{order_by}, '(id, ts)',           'order_by extracted');
    is($p->{sample_by}, 'id',                'sample_by extracted');
    is($p->{ttl}, 'ts + INTERVAL 90 DAY',    'ttl extracted');
    is($p->{settings}, 'index_granularity = 8192', 'settings extracted');
    is_deeply($p->{columns}, [
        ['id',      'UInt64'],
        ['name',    'String'],
        ['ts',      'DateTime'],
        ['payload', 'Nullable(String)'],
        ['tags',    'Array(LowCardinality(String))'],
    ], 'columns parsed as [name, type], modifiers stripped from type');
}

# Types with internal commas (Decimal, named Tuple) must not be split.
{
    my $ddl = 'CREATE TABLE t ('
            . '`price` Decimal(18, 4), '
            . '`pair` Tuple(a Int32, b String), '
            . '`m` Map(String, Array(Int64))'
            . ') ENGINE = Memory';
    my $p = ClickHouse::Encoder->parse_create_table($ddl);
    is_deeply($p->{columns}, [
        ['price', 'Decimal(18, 4)'],
        ['pair',  'Tuple(a Int32, b String)'],
        ['m',     'Map(String, Array(Int64))'],
    ], 'paren-aware column split keeps nested commas intact');
    is($p->{engine}, 'Memory', 'engine with no other clauses');
}

# No database qualifier -> database is undef, table still set.
{
    my $p = ClickHouse::Encoder->parse_create_table(
        'CREATE TABLE bare (`x` Int32) ENGINE = Memory');
    is($p->{database}, undef, 'unqualified name -> undef database');
    is($p->{table},    'bare', 'unqualified table name');
}

# IF NOT EXISTS and backtick-quoted qualified name.
{
    my $p = ClickHouse::Encoder->parse_create_table(
        'CREATE TABLE IF NOT EXISTS `my-db`.`my tbl` '
      . '(`c` Int32) ENGINE = Memory');
    is($p->{database}, 'my-db',  'backtick database with hyphen');
    is($p->{table},    'my tbl', 'backtick table with space');
}

# Identifiers containing a literal backtick: CH's SHOW CREATE TABLE (and
# format_create_table) backslash-escape it as \` inside the quotes, so
# the parser must decode that escape rather than treat it as the end of
# the quoted region.
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 'tbl',
        columns => [['we`ird', 'Int32'], ['ok', 'String']],
        engine  => 'Memory',
    );
    my $p = ClickHouse::Encoder->parse_create_table($sql);
    is_deeply($p->{columns}, [['we`ird', 'Int32'], ['ok', 'String']],
              'backtick-in-name round-trips format -> parse');
}

# The doubled-backtick escape form is also accepted on input.
{
    my $p = ClickHouse::Encoder->parse_create_table(
        'CREATE TABLE t (`a``b` Int32) ENGINE = Memory');
    is_deeply($p->{columns}, [['a`b', 'Int32']],
              'doubled-backtick escape decoded on input');
}

# CREATE OR REPLACE TABLE and CREATE TEMPORARY TABLE header variants.
{
    my $p = ClickHouse::Encoder->parse_create_table(
        'CREATE OR REPLACE TABLE t (`x` Int32) ENGINE = Memory');
    is($p->{table}, 't', 'CREATE OR REPLACE TABLE header parsed');

    my $q = ClickHouse::Encoder->parse_create_table(
        'CREATE TEMPORARY TABLE tmp (`y` String) ENGINE = Memory');
    is($q->{table}, 'tmp', 'CREATE TEMPORARY TABLE header parsed');
}

# Round-trip: parse -> schema_diff against a changed shape -> ALTERs.
{
    my $p = ClickHouse::Encoder->parse_create_table(
        'CREATE TABLE t (`a` Int32, `b` String) ENGINE = Memory');
    my $diff = ClickHouse::Encoder->schema_diff(
        $p->{columns}, [['a', 'Int64'], ['c', 'DateTime']]);
    my $sql = ClickHouse::Encoder->apply_schema_diff($diff, table => 't');
    is_deeply($sql, [
        'alter table `t` drop column `b`',
        'alter table `t` modify column `a` Int64',
        'alter table `t` add column `c` DateTime',
    ], 'parsed columns feed straight into schema_diff + apply_schema_diff');
}

# Error paths.
{
    local $@;
    eval { ClickHouse::Encoder->parse_create_table(undef) };
    like($@, qr/input required/, 'undef input croaks');
    eval { ClickHouse::Encoder->parse_create_table('SELECT 1') };
    like($@, qr/no create table header/, 'non-DDL input croaks');
    eval { ClickHouse::Encoder->parse_create_table('CREATE TABLE t') };
    like($@, qr/no column list/, 'missing column block croaks');
    eval { ClickHouse::Encoder->parse_create_table(
        'CREATE TABLE t (`a` Int32') };
    like($@, qr/unbalanced column list/,
         'column block with no closing paren croaks');
}

done_testing();
