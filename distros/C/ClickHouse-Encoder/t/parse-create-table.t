use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# parse_create_table turns a show create table string back into the
# structured shape schema_diff / format_create_table consume.

# Full DDL with every trailing clause.
{
    my $ddl = <<'DDL';
create table analytics.events
(
    `id` UInt64,
    `name` String default 'anon',
    `ts` DateTime codec(DoubleDelta, LZ4),
    `payload` Nullable(String),
    `tags` Array(LowCardinality(String))
)
engine = MergeTree
partition by toYYYYMM(ts)
primary key id
order by (id, ts)
sample by id
ttl ts + interval 90 day
settings index_granularity = 8192
DDL
    my $p = ClickHouse::Encoder->parse_create_table($ddl);
    is($p->{database}, 'analytics',          'database extracted');
    is($p->{table},    'events',             'table extracted');
    is($p->{engine},   'MergeTree',          'engine extracted');
    is($p->{partition_by}, 'toYYYYMM(ts)',   'partition_by extracted');
    is($p->{primary_key},  'id',             'primary_key extracted');
    is($p->{order_by}, '(id, ts)',           'order_by extracted');
    is($p->{sample_by}, 'id',                'sample_by extracted');
    is($p->{ttl}, 'ts + interval 90 day',    'ttl extracted');
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
    my $ddl = 'create table t ('
            . '`price` Decimal(18, 4), '
            . '`pair` Tuple(a Int32, b String), '
            . '`m` Map(String, Array(Int64))'
            . ') engine = Memory';
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
        'create table bare (`x` Int32) engine = Memory');
    is($p->{database}, undef, 'unqualified name -> undef database');
    is($p->{table},    'bare', 'unqualified table name');
}

# if not exists and backtick-quoted qualified name.
{
    my $p = ClickHouse::Encoder->parse_create_table(
        'create table if not exists `my-db`.`my tbl` '
      . '(`c` Int32) engine = Memory');
    is($p->{database}, 'my-db',  'backtick database with hyphen');
    is($p->{table},    'my tbl', 'backtick table with space');
}

# Identifiers containing a literal backtick: CH's show create table (and
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
        'create table t (`a``b` Int32) engine = Memory');
    is_deeply($p->{columns}, [['a`b', 'Int32']],
              'doubled-backtick escape decoded on input');
}

# create or replace table and create temporary table header variants.
{
    my $p = ClickHouse::Encoder->parse_create_table(
        'create or replace table t (`x` Int32) engine = Memory');
    is($p->{table}, 't', 'create or replace table header parsed');

    my $q = ClickHouse::Encoder->parse_create_table(
        'create temporary table tmp (`y` String) engine = Memory');
    is($q->{table}, 'tmp', 'create temporary table header parsed');
}

# Round-trip: parse -> schema_diff against a changed shape -> alters.
{
    my $p = ClickHouse::Encoder->parse_create_table(
        'create table t (`a` Int32, `b` String) engine = Memory');
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
    eval { ClickHouse::Encoder->parse_create_table('select 1') };
    like($@, qr/no create table header/, 'non-DDL input croaks');
    eval { ClickHouse::Encoder->parse_create_table('create table t') };
    like($@, qr/no column list/, 'missing column block croaks');
    eval { ClickHouse::Encoder->parse_create_table(
        'create table t (`a` Int32') };
    like($@, qr/unbalanced column list/,
         'column block with no closing paren croaks');
}

# TabSeparated-escaped DDL, as `show create table` arrives over HTTP: the
# newlines come through as the two characters \ and n, which used to leave
# the column block one unsplittable run and fail with "no columns parsed".
{
    # TabSeparated output shape from ClickHouse 26.7.1.
    my $escaped = 'create table default.http_live\n(\n    `id` UInt32,'
                . '\n    `name` String,\n    `ts` DateTime,'
                . '\n    `val` Nullable(Float64)\n)\nengine = Memory' . "\n";
    my $info = ClickHouse::Encoder->parse_create_table($escaped);
    is($info->{table}, 'http_live', 'escaped DDL: table name');
    is($info->{database}, 'default', 'escaped DDL: database');
    is_deeply($info->{columns},
              [['id','UInt32'], ['name','String'], ['ts','DateTime'],
               ['val','Nullable(Float64)']],
              'escaped DDL: all columns recovered');
    is($info->{engine}, 'Memory', 'escaped DDL: engine');

    # The same DDL unescaped must parse identically.
    (my $plain = $escaped) =~ s/\\n/\n/g;
    is_deeply(ClickHouse::Encoder->parse_create_table($plain)->{columns},
              $info->{columns}, 'escaped and plain forms agree');
}

# The unescape must not fire on DDL that genuinely contains backslashes.
# It keys off the escaped column-block opener the server always emits, not
# merely on a backslash being present, so a caller's own SQL is never
# rewritten - clause text included, which is returned verbatim.
{
    my $ddl = "create table t\n(\n  `a` String default 'x\\ny',\n"
            . "  `b` UInt32\n)\nengine = Memory";
    my $info = ClickHouse::Encoder->parse_create_table($ddl);
    is_deeply([map { $_->[0] } @{ $info->{columns} }], ['a','b'],
              'real-newline DDL containing a backslash escape is left alone');

    my $one_line = q{create table t (`a` String) engine = MergeTree }
                 . q{order by a settings x = 'a\nb'};
    my $flat = ClickHouse::Encoder->parse_create_table($one_line);
    is_deeply([map { $_->[0] } @{ $flat->{columns} }], ['a'],
              'single-line DDL with a backslash literal still parses');
    like($flat->{settings}, qr/\Qa\nb\E/,
         'single-line DDL: backslash in a clause is not rewritten');
    unlike($flat->{settings}, qr/\n/,
           'single-line DDL: no spurious newline injected into a clause');
}

done_testing();
