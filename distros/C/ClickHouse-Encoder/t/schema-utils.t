#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# schema_diff -----------------------------------------------------------
{
    my $d = ClickHouse::Encoder->schema_diff(
        [['a','Int32'], ['b','String']],
        [['a','Int32'], ['b','String']],
    );
    is_deeply($d, { added=>[], removed=>[], changed=>[] },
              'identical schemas: empty diff');
}

{
    my $d = ClickHouse::Encoder->schema_diff(
        [['a','Int32']],
        [['a','Int32'], ['b','String']],
    );
    is_deeply($d, {
        added   => [['b','String']],
        removed => [],
        changed => [],
    }, 'one column added');
}

{
    my $d = ClickHouse::Encoder->schema_diff(
        [['a','Int32'], ['b','String']],
        [['a','Int32']],
    );
    is_deeply($d, {
        added   => [],
        removed => [['b','String']],
        changed => [],
    }, 'one column removed');
}

{
    my $d = ClickHouse::Encoder->schema_diff(
        [['a','Int32']],
        [['a','UInt32']],
    );
    is_deeply($d, {
        added   => [],
        removed => [],
        changed => [['a','Int32','UInt32']],
    }, 'one column type changed');
}

# Mixed: added + removed + changed in one diff
{
    my $d = ClickHouse::Encoder->schema_diff(
        [['a','Int32'], ['b','String'], ['c','Float64']],
        [['a','UInt32'], ['c','Float64'], ['d','Bool']],
    );
    is_deeply($d->{added},   [['d','Bool']],         'mixed: added');
    is_deeply($d->{removed}, [['b','String']],       'mixed: removed');
    is_deeply($d->{changed}, [['a','Int32','UInt32']], 'mixed: changed');
}

# Empty inputs
{
    my $d = ClickHouse::Encoder->schema_diff([], []);
    is_deeply($d, { added=>[], removed=>[], changed=>[] },
              'empty vs empty');
    my $d2 = ClickHouse::Encoder->schema_diff([], [['x','Int8']]);
    is_deeply($d2->{added}, [['x','Int8']], 'all-added against empty');
}

# estimate_size --------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['id', 'Int32'], ['name', 'String'],
    ]);
    # 100 rows: Int32 = 4 bytes/row, String ~17 bytes/row (with default avg).
    # Plus headers. Compare to encode-actual within a factor.
    my $est = $enc->estimate_size(100);
    cmp_ok($est, '>', 100 * 4,  'estimate exceeds Int32 floor');
    cmp_ok($est, '<', 100 * 100, 'estimate not absurdly large');

    # Real encode with short strings should be within 4x of the estimate.
    my @rows = map [[$_, "u$_"]], 1..100;
    my $actual = length $enc->encode([ map [$_, "u$_"], 1..100 ]);
    cmp_ok($est, '>', $actual * 0.3, 'estimate within 0.3x..3x of actual');
    cmp_ok($est, '<', $actual * 3,   'estimate within 0.3x..3x of actual');
}

# estimate_size accepts arrayref too (counts rows)
{
    my $enc = ClickHouse::Encoder->new(columns => [['x','Int32']]);
    my $by_count = $enc->estimate_size(50);
    my $by_array = $enc->estimate_size([ map [[$_]], 1..50 ]);
    is($by_count, $by_array, 'arrayref form == count form');
}

# Per-type sanity
{
    my $enc_fs = ClickHouse::Encoder->new(columns => [['p','FixedString(8)']]);
    my $est = $enc_fs->estimate_size(1000);
    cmp_ok($est, '>=', 8 * 1000, 'FixedString(8) estimate covers 8*N bytes');

    my $enc_arr = ClickHouse::Encoder->new(columns => [['a','Array(Int32)']]);
    my $est_arr = $enc_arr->estimate_size(100);
    cmp_ok($est_arr, '>', 100 * 8, 'Array estimate covers offset bytes');

    my $enc_lc = ClickHouse::Encoder->new(columns => [['lc','LowCardinality(String)']]);
    cmp_ok($enc_lc->estimate_size(1000), '>', 1000,
           'LowCardinality estimate non-trivial');
}

# avg_string_size override
{
    my $enc = ClickHouse::Encoder->new(columns => [['s','String']]);
    my $small = $enc->estimate_size(100, avg_string_size => 4);
    my $large = $enc->estimate_size(100, avg_string_size => 256);
    cmp_ok($large, '>', $small * 5,
           'avg_string_size override scales estimate');
}

# JSON estimate scales with avg_string_size too (regression: it used
# to be hardcoded to 32 bytes/row and ignored the override).
{
    my $enc = ClickHouse::Encoder->new(columns => [['j','JSON']]);
    my $small = $enc->estimate_size(100, avg_string_size => 8);
    my $large = $enc->estimate_size(100, avg_string_size => 256);
    cmp_ok($large, '>', $small * 5,
           'avg_string_size override scales JSON estimate');
}

# format_create_table -----------------------------------------------
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 'events',
        columns => [['id','Int32'], ['msg','String'], ['ts','DateTime']],
        order_by => '(id, ts)',
    );
    like($sql, qr/create table `events`/, 'CREATE TABLE header');
    like($sql, qr/`id` Int32/,            'first column emitted');
    like($sql, qr/`msg` String/,          'middle column emitted');
    like($sql, qr/`ts` DateTime/,         'last column emitted');
    like($sql, qr/engine = MergeTree/,    'default engine MergeTree');
    like($sql, qr/order by \(id, ts\)/,   'order by clause emitted');
    unlike($sql, qr/partition by/,        'no partition by when not given');
}

# format_create_table: backtick escaping
{
    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 'evt',
        columns => [['weird`col', 'String']]);
    like($sql, qr/\\`/, 'backtick in column name is escaped');
}

# format_create_table: validates table name (no SQL injection)
{
    my $err = eval {
        ClickHouse::Encoder->format_create_table(
            table   => 'foo; drop table bar',
            columns => [['x','Int32']]); 1
    } ? '' : $@;
    like($err, qr/Invalid table name/i, 'rejects bad table name');
}

# apply_schema_diff -------------------------------------------------
{
    my $diff = ClickHouse::Encoder->schema_diff(
        [['a','Int32'], ['b','String'], ['c','Float64']],
        [['a','UInt32'], ['c','Float64'], ['d','Bool']],
    );
    my $stmts = ClickHouse::Encoder->apply_schema_diff(
        $diff, table => 'evt');
    is(ref $stmts, 'ARRAY', 'returns arrayref');
    # Drops first, then modifies, then adds
    like($stmts->[0], qr/drop column `b`/,           'drop comes first');
    like($stmts->[1], qr/modify column `a` UInt32/,  'modify in middle');
    like($stmts->[2], qr/add column `d` Bool/,       'add comes last');
    is(scalar @$stmts, 3, 'three statements for mixed diff');
}

# apply_schema_diff: identical schemas -> empty list
{
    my $diff = ClickHouse::Encoder->schema_diff(
        [['a','Int32']], [['a','Int32']]);
    my $stmts = ClickHouse::Encoder->apply_schema_diff(
        $diff, table => 'evt');
    is_deeply($stmts, [], 'no-op diff -> empty stmts');
}

# for_native_bytes --------------------------------------------------
{
    my $original = ClickHouse::Encoder->new(columns =>
        [['x','Int32'], ['s','String']]);
    my $bytes = $original->encode([[1,'a'], [2,'bb']]);
    my $rebuilt = ClickHouse::Encoder->for_native_bytes($bytes);
    isa_ok($rebuilt, 'ClickHouse::Encoder');
    is_deeply($rebuilt->columns, [['x','Int32'], ['s','String']],
              'for_native_bytes reconstructs the column shape');
    # And it can encode new rows in the same shape
    my $more = $rebuilt->encode([[3,'ccc']]);
    my $blk  = ClickHouse::Encoder->decode_block($more);
    is($blk->{nrows}, 1, 'rebuilt encoder produces decodable bytes');
}

# for_native_bytes on a zero-row block (column headers only)
{
    my $enc = ClickHouse::Encoder->new(columns =>
        [['k','UInt64'], ['v','Float64']]);
    my $bytes = $enc->encode([]);
    my $rebuilt = ClickHouse::Encoder->for_native_bytes($bytes);
    is_deeply($rebuilt->columns, [['k','UInt64'], ['v','Float64']],
              'for_native_bytes works on zero-row blocks');
}

done_testing();
