#!/usr/bin/env perl
# Pin exact wire bytes for the integer/float boundary values that
# C-level encoding-and-casting bugs most often hide in: signed-int
# min/max, unsigned-int max, Float32 denormals, Float32/64 subnormals,
# negative-zero. Catches sign-extension and bitcast regressions.
use strict;
use warnings;
no warnings 'portable';   # the 64-bit hex literals are intentional
use lib 'blib/lib', 'blib/arch';
use Test::More;
use ClickHouse::Encoder;

# Strip block + col header to reach the start of column data.
sub tail_bytes {
    my ($bin, $n) = @_;
    return substr($bin, length($bin) - $n);
}

# Signed integer boundaries -----------------------------------------------
for my $case (
    ['Int8',   -128,                   "\x80"],
    ['Int8',   127,                    "\x7f"],
    ['Int16',  -32768,                 "\x00\x80"],
    ['Int16',  32767,                  "\xff\x7f"],
    ['Int32',  -(2**31),               "\x00\x00\x00\x80"],
    ['Int32',  2**31 - 1,              "\xff\xff\xff\x7f"],
    ['Int64',  '-9223372036854775808', "\x00\x00\x00\x00\x00\x00\x00\x80"],
    ['Int64',  '9223372036854775807',  "\xff\xff\xff\xff\xff\xff\xff\x7f"],
) {
    my ($type, $in, $want) = @$case;
    my $enc = ClickHouse::Encoder->new(columns => [['v', $type]]);
    my $bin = $enc->encode([[$in]]);
    is(tail_bytes($bin, length($want)), $want, "$type boundary: $in");
}

# Unsigned max ------------------------------------------------------------
for my $case (
    ['UInt8',  255,                     "\xff"],
    ['UInt16', 65535,                   "\xff\xff"],
    ['UInt32', 4_294_967_295,           "\xff\xff\xff\xff"],
    ['UInt64', '18446744073709551615',  "\xff\xff\xff\xff\xff\xff\xff\xff"],
) {
    my ($type, $in, $want) = @$case;
    my $enc = ClickHouse::Encoder->new(columns => [['v', $type]]);
    my $bin = $enc->encode([[$in]]);
    is(tail_bytes($bin, length($want)), $want, "$type max: $in");
}

# Float32 ------------------------------------------------------------------
# +0.0, -0.0 (must preserve sign bit), denormal min, normal min, max.
for my $case (
    ['+0.0',                  0.0,                              "\x00\x00\x00\x00"],
    ['-0.0',                  -0.0,                             "\x00\x00\x00\x80"],
    ['Float32 denormal min',  '1.401298464324817e-45' + 0,      "\x01\x00\x00\x00"],
    ['Float32 normal min',    '1.1754943508222875e-38' + 0,     "\x00\x00\x80\x00"],
    ['Float32 max',           '3.4028234663852886e+38' + 0,     "\xff\xff\x7f\x7f"],
) {
    my ($label, $in, $want) = @$case;
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Float32']]);
    my $bin = $enc->encode([[$in]]);
    is(tail_bytes($bin, 4), $want, "Float32: $label");
}

# Float64 ------------------------------------------------------------------
# Build the Float64 max from its actual bit pattern instead of relying on
# Perl's string-to-NV parser (pre-5.24 parsers round the literal slightly
# differently, producing a 1-ULP-off bit pattern).
my $f64_max = unpack 'd<', "\xff\xff\xff\xff\xff\xff\xef\x7f";
for my $case (
    ['+0.0',  0.0,  "\x00\x00\x00\x00\x00\x00\x00\x00"],
    ['-0.0', -0.0,  "\x00\x00\x00\x00\x00\x00\x00\x80"],
    # Float64 denormal min = 5e-324 (smallest representable subnormal)
    ['Float64 denormal min', '5e-324' + 0, "\x01\x00\x00\x00\x00\x00\x00\x00"],
    # Float64 max - reconstructed from bits to dodge old parser quirks.
    ['Float64 max', $f64_max, "\xff\xff\xff\xff\xff\xff\xef\x7f"],
) {
    my ($label, $in, $want) = @$case;
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Float64']]);
    my $bin = $enc->encode([[$in]]);
    is(tail_bytes($bin, 8), $want, "Float64: $label");
}

# BFloat16 boundaries ------------------------------------------------------
# BFloat16 = top 16 bits of Float32. Sign of +0 / -0 must survive.
for my $case (
    ['+0.0', 0.0,  "\x00\x00"],
    ['-0.0', -0.0, "\x00\x80"],
    ['1.0',  1.0,  "\x80\x3f"],
    ['-1.0',-1.0,  "\x80\xbf"],
) {
    my ($label, $in, $want) = @$case;
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'BFloat16']]);
    my $bin = $enc->encode([[$in]]);
    is(tail_bytes($bin, 2), $want, "BFloat16: $label");
}

# Decimal128 / Decimal256 boundaries via string path (exact arithmetic) ---
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal128(0)']]);
    # 2^127 - 1 = 170141183460469231731687303715884105727 (max signed 128)
    my $bin = $enc->encode([['170141183460469231731687303715884105727']]);
    is(tail_bytes($bin, 16),
       "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x7f",
       'Decimal128(0): 2^127 - 1 wire bytes');

    # -(2^127) = -170141183460469231731687303715884105728 (min signed 128)
    $bin = $enc->encode([['-170141183460469231731687303715884105728']]);
    is(tail_bytes($bin, 16),
       "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80",
       'Decimal128(0): -2^127 wire bytes (two\'s complement)');
}

done_testing();
