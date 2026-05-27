#!/usr/bin/env perl
# Encoder -> Decoder round-trip across every supported type. The
# Decoder lives in pure Perl (lib/ClickHouse/Encoder/Decoder.pm) and
# is symmetric with the XS encoder; this test pins that symmetry.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Test::More;
use ClickHouse::Encoder;
use TestCH qw(skip_header);

sub round {
    my ($cols, $rows) = @_;
    my $enc   = ClickHouse::Encoder->new(columns => $cols);
    my $bytes = $enc->encode($rows);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    return ($block, $bytes);
}

# Scalars ------------------------------------------------------------------
{
    my ($block) = round(
        [['i8','Int8'],   ['i64','Int64'], ['u32','UInt32'],
         ['f32','Float32'],['f64','Float64'],['bf','BFloat16'],
         ['s','String'],  ['fs','FixedString(4)'],
         ['b','Bool']],
        [
            [-128, '9223372036854775807', 4_294_967_295,
             1.5, 3.14, 1.0,
             'hello', 'abcd',
             1],
            [127, '-9223372036854775808', 0,
             -1.5, -2.71828, -1.0,
             '', 'xy',
             0],
        ],
    );
    is_deeply($block->{columns}[0]{values}, [-128, 127],     'Int8 round-trip');
    is_deeply($block->{columns}[1]{values},
              ['9223372036854775807', '-9223372036854775808'],
              'Int64 round-trip (string-safe boundaries)');
    is_deeply($block->{columns}[2]{values}, [4_294_967_295, 0], 'UInt32 round-trip');
    is($block->{columns}[3]{values}[0], 1.5,  'Float32 round-trip +1.5');
    is($block->{columns}[4]{values}[1], -2.71828, 'Float64 round-trip');
    is($block->{columns}[5]{values}[0], 1.0,  'BFloat16 round-trip 1.0');
    is_deeply($block->{columns}[6]{values}, ['hello', ''], 'String round-trip');
    is_deeply($block->{columns}[7]{values}, ['abcd', "xy\x00\x00"],
                                                          'FixedString round-trip (zero-padded)');
    is_deeply($block->{columns}[8]{values}, [1, 0],       'Bool round-trip');
}

# Date / DateTime / DateTime64 --------------------------------------------
{
    my ($block) = round(
        [['d','Date'], ['dt','DateTime'], ['dt64','DateTime64(3)']],
        [
            ['2024-06-15', '2024-06-15 12:30:45', '2024-06-15 12:30:45.123'],
            [0,            0,                     0],
        ],
    );
    # Date / DateTime decode as integers (days / seconds since epoch).
    cmp_ok($block->{columns}[0]{values}[0], '>', 0,  'Date decodes to days int');
    cmp_ok($block->{columns}[1]{values}[0], '>', 1e9,'DateTime decodes to seconds int');
    cmp_ok($block->{columns}[2]{values}[0], '>', 0,  'DateTime64 decodes to scaled int');
    is($block->{columns}[0]{values}[1], 0, 'Date epoch zero round-trips');
}

# Decimal128 / Decimal256 limb decode + helper ----------------------------
{
    my ($block) = round(
        [['d128','Decimal128(2)'], ['d256','Decimal256(4)']],
        [
            ['12345.67',                      '99999999.9999'],
            ['-99999999999999.99',            '-1.0001'],
        ],
    );
    my $d128 = $block->{columns}[0]{values}[0];
    is(ref $d128, 'ARRAY', 'Decimal128 decodes as [lo,hi]');
    is(
        ClickHouse::Encoder->decimal128_str(@$d128, 2),
        '12345.67',
        'Decimal128 +12345.67 string round-trip'
    );
    is(
        ClickHouse::Encoder->decimal128_str(
            @{ $block->{columns}[0]{values}[1] }, 2),
        '-99999999999999.99',
        'Decimal128 negative string round-trip'
    );

    my $d256_pos = $block->{columns}[1]{values}[0];
    is(ref $d256_pos, 'ARRAY', 'Decimal256 decodes as 4-limb arrayref');
    is(
        ClickHouse::Encoder->decimal256_str($d256_pos, 4),
        '99999999.9999',
        'Decimal256 positive string round-trip'
    );
    my $d256_neg = $block->{columns}[1]{values}[1];
    is(
        ClickHouse::Encoder->decimal256_str($d256_neg, 4),
        '-1.0001',
        'Decimal256 negative string round-trip'
    );
}

# UUID -> canonical hex form -----------------------------------------------
{
    my ($block) = round(
        [['u','UUID']],
        [['11112222-3333-4444-5555-666677778888'],
         ['00000000-0000-0000-0000-000000000000']],
    );
    is_deeply($block->{columns}[0]{values},
              ['11112222-3333-4444-5555-666677778888',
               '00000000-0000-0000-0000-000000000000'],
              'UUID round-trip');
}

# IPv4 / IPv6 -------------------------------------------------------------
{
    my ($block) = round(
        [['v4','IPv4'], ['v6','IPv6']],
        [['127.0.0.1', "\x00" x 15 . "\x01"]],
    );
    is($block->{columns}[0]{values}[0], '127.0.0.1', 'IPv4 round-trip');
    is(length $block->{columns}[1]{values}[0], 16, 'IPv6 keeps 16 raw bytes');
}

# IPv4 decode pinned against literal wire bytes. A pure round-trip
# test cancels out a symmetric encoder/decoder byte-order bug; this
# constructs the wire bytes manually so the decoder must produce the
# right octet order on any host endianness.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v4','IPv4']]);
    my $one = $enc->encode([['0.0.0.0']]);     # known shape, then overwrite
    my $off = skip_header($one);
    my $wire = substr($one, 0, $off) . "\x04\x03\x02\x01";  # LE = 1.2.3.4
    my $block = ClickHouse::Encoder->decode_block($wire);
    is($block->{columns}[0]{values}[0], '1.2.3.4',
       'IPv4 decode of pinned wire bytes [04][03][02][01] = "1.2.3.4"');
}

# Endianness-portable decode helpers (dec_le16 / dec_le32 / dec_le64):
# pin literal LE byte sequences against expected integer/float outputs.
# A round-trip test would cancel out a symmetric host-endian bug; these
# hand-built wire buffers prove the decoder reads LE on any host.
sub _build_block {
    my ($type, $body) = @_;
    my $enc = ClickHouse::Encoder->new(columns => [['c', $type]]);
    my $sample = $enc->encode([]);   # ncols/nrows=0 + name+type
    # Replace nrows=0 with nrows=1 (varint 0 is one byte: 0x00). The
    # block layout right after ncols (also one varint byte) is the
    # nrows varint, so the second byte of $sample is nrows. Increment.
    my $hdr = substr($sample, 0, 1) . "\x01" . substr($sample, 2);
    return $hdr . $body;
}
{
    # Int32 = -1 on the wire is 0xFFFFFFFF (LE bytes [FF FF FF FF])
    my $b = ClickHouse::Encoder->decode_block(
        _build_block('Int32', "\xff\xff\xff\xff"));
    is($b->{columns}[0]{values}[0], -1, 'Int32 LE [FF*4] -> -1');

    # Int32 = INT32_MAX = 0x7FFFFFFF (LE bytes [FF FF FF 7F])
    $b = ClickHouse::Encoder->decode_block(
        _build_block('Int32', "\xff\xff\xff\x7f"));
    is($b->{columns}[0]{values}[0], 2147483647, 'Int32 LE [FF FF FF 7F] -> INT32_MAX');

    # UInt32 = 0x01020304 (LE bytes [04 03 02 01])
    $b = ClickHouse::Encoder->decode_block(
        _build_block('UInt32', "\x04\x03\x02\x01"));
    is($b->{columns}[0]{values}[0], 0x01020304, 'UInt32 LE [04 03 02 01] -> 0x01020304');

    # UInt64 = 0x0807060504030201 (LE bytes [01..08]); build the
    # expected value via shifts to keep the literal portable.
    $b = ClickHouse::Encoder->decode_block(
        _build_block('UInt64', "\x01\x02\x03\x04\x05\x06\x07\x08"));
    is($b->{columns}[0]{values}[0],
       0x0807_0605 * (1 << 32) + 0x0403_0201,
       'UInt64 LE [01..08] -> 0x0807060504030201');

    # Float64 = 1.0 (IEEE 754 binary64 = 0x3FF0000000000000, LE bytes
    # [00 00 00 00 00 00 F0 3F])
    $b = ClickHouse::Encoder->decode_block(
        _build_block('Float64', "\x00\x00\x00\x00\x00\x00\xf0\x3f"));
    cmp_ok($b->{columns}[0]{values}[0], '==', 1.0,
       'Float64 LE 0x3FF0000000000000 -> 1.0');
}

# Map / Array / Tuple / Nullable composites ------------------------------
{
    my ($block) = round(
        [['m','Map(String, UInt32)'],
         ['a','Array(Nullable(Int32))'],
         ['t','Tuple(a Int32, b Nullable(String))']],
        [
            [{x=>1,y=>2}, [1, undef, 3], [42, 'hi']],
            [{},          [],            [99, undef]],
        ],
    );
    # Map decodes as Array(Tuple(K,V)) on wire.
    is(scalar @{$block->{columns}[0]{values}[0]}, 2, 'Map row 0 has 2 entries');
    is_deeply($block->{columns}[1]{values}, [[1, undef, 3], []],
              'Array(Nullable) preserves middle null');
    is_deeply($block->{columns}[2]{values}, [[42, 'hi'], [99, undef]],
              'Tuple(a, b) decodes to positional arrayref');
}

# LowCardinality ----------------------------------------------------------
{
    my ($block) = round(
        [['lc','LowCardinality(String)'],
         ['lcn','LowCardinality(Nullable(String))']],
        [
            ['repeated', 'a'],
            ['repeated', undef],
            ['other',    'a'],
        ],
    );
    is_deeply($block->{columns}[0]{values},
              ['repeated','repeated','other'],
              'LC(String) dict lookup');
    is_deeply($block->{columns}[1]{values},
              ['a', undef, 'a'],
              'LC(Nullable(String)) preserves null slot 0');
}

# Variant: index returned is declaration order, not alphabetical wire idx.
{
    # Declaration is not alphabetical (UInt32 < String); encoder
    # remaps to wire alphabetical, decoder must remap back.
    my ($block) = round(
        [['v','Variant(UInt32, String)']],
        [
            [[0, 42]],         # decl idx 0 = UInt32
            [[1, 'hi']],       # decl idx 1 = String
            [undef],           # null
        ],
    );
    is_deeply($block->{columns}[0]{values},
              [[0, 42], [1, 'hi'], undef],
              'Variant returns declaration-order indices');
}

# decode_rows view --------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['n','Int32'], ['s','String']]);
    my $bin = $enc->encode([[1, 'a'], [2, 'b'], [3, 'c']]);
    my $r = ClickHouse::Encoder->decode_rows($bin);
    is($r->{ncols}, 2,          'decode_rows: ncols');
    is($r->{nrows}, 3,          'decode_rows: nrows');
    is_deeply($r->{names}, ['n','s'],         'decode_rows: column names');
    is_deeply($r->{types}, ['Int32','String'], 'decode_rows: column types');
    is_deeply($r->{rows},
              [[1,'a'], [2,'b'], [3,'c']],
              'decode_rows: rows are arrayrefs in column-spec order');

    # The direct XS row-major decoder produces the same shape.
    my $r2 = ClickHouse::Encoder->decode_block_rows($bin);
    is_deeply($r2->{rows}, $r->{rows},
              'decode_block_rows: same row payload as decode_rows');
    is($r2->{consumed}, length $bin,
       'decode_block_rows: consumed equals input length');
    # Offset form
    my $bin2 = $bin . $enc->encode([[9, 'z']]);
    my $r3 = ClickHouse::Encoder->decode_block_rows($bin2, $r->{consumed}
        // length $bin);
    is_deeply($r3->{rows}, [[9, 'z']],
              'decode_block_rows: offset form picks the second block');
}

# Concatenated blocks via `consumed` -------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Int32']]);
    my $bin = $enc->encode([[1],[2]]) . $enc->encode([[3]]);
    my $b1  = ClickHouse::Encoder->decode_block($bin);
    my $b2  = ClickHouse::Encoder->decode_block(substr($bin, $b1->{consumed}));
    is_deeply($b1->{columns}[0]{values}, [1,2], 'first block');
    is_deeply($b2->{columns}[0]{values}, [3],   'second block (offset via consumed)');
}

done_testing();
