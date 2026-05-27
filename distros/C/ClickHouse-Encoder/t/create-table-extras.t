use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# format_create_table per-column extras: default/materialized/alias,
# codec, per-column ttl, comment, and the table-level ttl clause.

# Plain [name, type] entries still work (backward compatibility).
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 't',
        columns => [['id', 'UInt64'], ['name', 'String']],
        engine  => 'MergeTree', order_by => 'id',
    );
    like($sql,   qr/`id` UInt64,/,         'bare column entry');
    unlike($sql, qr/ default | codec\(/,   'no spurious modifiers');
}

# default + codec + comment on one column.
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 'events',
        columns => [
            ['id',   'UInt64'],
            ['ts',   'DateTime', { codec => 'DoubleDelta, LZ4' }],
            ['kind', 'String',   { default => "'unknown'",
                                   comment => "event kind" }],
        ],
        engine => 'MergeTree', order_by => '(id, ts)',
        ttl    => 'ts + INTERVAL 30 DAY',
    );
    like($sql, qr/`ts` DateTime codec\(DoubleDelta, LZ4\)/,
         'per-column codec rendered');
    like($sql, qr/`kind` String default 'unknown' comment 'event kind'/,
         'default + comment rendered in order');
    like($sql, qr/\nttl ts \+ INTERVAL 30 DAY/,
         'table-level TTL clause rendered');
}

# MATERIALIZED and ALIAS each render with their keyword.
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 't',
        columns => [
            ['a', 'Int32'],
            ['b', 'Int32', { materialized => 'a * 2' }],
            ['c', 'Int32', { alias        => 'a + 1' }],
        ],
    );
    like($sql, qr/`b` Int32 materialized a \* 2/, 'materialized column');
    like($sql, qr/`c` Int32 alias a \+ 1/,        'alias column');
}

# A per-column TTL plus codec, both present.
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 't',
        columns => [
            ['payload', 'String', { codec => 'ZSTD(3)',
                                    ttl   => 'event_date + INTERVAL 7 DAY' }],
        ],
    );
    like($sql, qr/`payload` String codec\(ZSTD\(3\)\) ttl event_date \+ INTERVAL 7 DAY/,
         'per-column codec then ttl');
}

# comment containing a single quote is escaped.
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 't',
        columns => [['x', 'Int32', { comment => "it's here" }]],
    );
    like($sql, qr/comment 'it\\'s here'/, 'single quote in comment escaped');
}

# comment containing a backslash: CH string literals process C-style
# escapes, so a literal backslash must itself be escaped (else "\n" in
# a comment would be read by the server as a newline).
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 't',
        columns => [['x', 'Int32', { comment => 'path C:\\new' }]],
    );
    like($sql, qr/comment 'path C:\\\\new'/,
         'backslash in comment doubled before quote-escaping');
}

# Identifier escaping: a column name containing a backtick and a
# backslash must both be backslash-escaped (matching CH backQuote()).
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 't',
        columns => [['we`ird', 'Int32'], ['back\\slash', 'Int32']],
    );
    like($sql, qr/`we\\`ird` Int32/,    'backtick in column name escaped');
    like($sql, qr/`back\\\\slash` Int32/,
         'backslash in column name escaped');
}

# sample_by support: format emits it, and the format -> parse round
# trip is symmetric for every table-level clause.
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table        => 'events',
        columns      => [['id', 'UInt64'], ['ts', 'DateTime']],
        engine       => 'MergeTree',
        partition_by => 'toYYYYMM(ts)',
        primary_key  => 'id',
        order_by     => '(id, ts)',
        sample_by    => 'id',
        ttl          => 'ts + INTERVAL 30 DAY',
        settings     => 'index_granularity = 8192',
    );
    like($sql, qr/sample by id/, 'format_create_table emits sample by');
    my $p = ClickHouse::Encoder->parse_create_table($sql);
    is($p->{engine},       'MergeTree',                'roundtrip: engine');
    is($p->{partition_by}, 'toYYYYMM(ts)',             'roundtrip: partition_by');
    is($p->{primary_key},  'id',                       'roundtrip: primary_key');
    is($p->{order_by},     '(id, ts)',                 'roundtrip: order_by');
    is($p->{sample_by},    'id',                       'roundtrip: sample_by');
    is($p->{ttl},          'ts + INTERVAL 30 DAY',     'roundtrip: ttl');
    is($p->{settings},     'index_granularity = 8192', 'roundtrip: settings');
}

# default + materialized on the same column is a contradiction -> croak.
{
    local $@;
    eval {
        ClickHouse::Encoder->format_create_table(
            table   => 't',
            columns => [['x', 'Int32',
                         { default => '1', materialized => '2' }]],
        );
    };
    like($@, qr/more than one of default\/materialized\/alias/,
         'mutually exclusive value kinds croak');
}

done_testing();
