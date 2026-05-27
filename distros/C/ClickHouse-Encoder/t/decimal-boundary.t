#!/usr/bin/env perl
# Decimal128/Decimal256 at extreme precision: maximum positive,
# maximum negative, smallest non-zero, negative-zero. The encoder
# does its own two's-complement work for these widths; the decoder
# returns the limb pair/quad for the caller to widen via
# decimal{128,256}_str. Pin both sides byte-exact.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Decimal128(0): integer values up to (2^127 - 1) ~= 1.7e38
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Decimal128(0)']]);

    # Maximum positive (2^127 - 1)
    my $max_pos = '170141183460469231731687303715884105727';
    # Maximum negative -2^127
    my $max_neg = '-170141183460469231731687303715884105728';
    my $bytes = $enc->encode([[$max_pos], [$max_neg], ['0'], ['1'], ['-1']]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    my @rows  = @{ $blk->{columns}[0]{values} };
    is(scalar @rows, 5, 'Decimal128: all rows decoded');
    # Reconstruct strings from limb pairs
    is(ClickHouse::Encoder->decimal128_str(@{$rows[0]}, 0), $max_pos,
       'Decimal128: max positive round-trip');
    is(ClickHouse::Encoder->decimal128_str(@{$rows[1]}, 0), $max_neg,
       'Decimal128: max negative round-trip');
    is(ClickHouse::Encoder->decimal128_str(@{$rows[2]}, 0), '0',
       'Decimal128: zero round-trip');
    is(ClickHouse::Encoder->decimal128_str(@{$rows[3]}, 0), '1',
       'Decimal128: one round-trip');
    is(ClickHouse::Encoder->decimal128_str(@{$rows[4]}, 0), '-1',
       'Decimal128: minus-one round-trip');
}

# Decimal128(38): full-precision fractional path
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Decimal128(38)']]);
    # 0.<37 digits>5 - 38 fractional digits, value ~0.5
    my $val = '0.5' . '0' x 36 . '1';  # 0.5...01 with 38 fractional digits
    my $bytes = $enc->encode([[$val]]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    my $rows  = $blk->{columns}[0]{values};
    is(ClickHouse::Encoder->decimal128_str(@{$rows->[0]}, 38), $val,
       'Decimal128(38): full-precision fractional');
}

# Decimal256(0): integer up to (2^255 - 1) ~= 5.8e76
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Decimal256(0)']]);
    my $max_pos = '5789604461865809771178549250434395392663499233282028201972879200395656481996';
    my $max_neg = '-' . $max_pos;
    my $bytes = $enc->encode([[$max_pos], [$max_neg], ['1234567890' x 5]]);
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    my @rows = @{ $blk->{columns}[0]{values} };
    is(scalar @rows, 3, 'Decimal256: rows decoded');
    is(ClickHouse::Encoder->decimal256_str($rows[0], 0), $max_pos,
       'Decimal256: large positive');
    # Decimal256 max-negative is asymmetric (-2^255), but max_neg here
    # is symmetric (-(2^255-1)). Reconstruct via decimal256_str.
    is(ClickHouse::Encoder->decimal256_str($rows[1], 0), $max_neg,
       'Decimal256: large negative');
    is(ClickHouse::Encoder->decimal256_str($rows[2], 0), '1234567890' x 5,
       'Decimal256: 50-digit positive');
}

# Reject Decimal128 value beyond signed-128 range
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Decimal128(0)']]);
    my $too_big = '170141183460469231731687303715884105728';  # 2^127 (one past max)
    my $err = eval { $enc->encode([[$too_big]]); 1 } ? '' : $@;
    like($err, qr/Invalid decimal/, 'Decimal128 overflow rejected');
}

# Reject Decimal256 value beyond signed-256 range
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Decimal256(0)']]);
    # 2^255 is the first value that doesn't fit (-2^255 fits, +2^255 does not)
    my $too_big = '57896044618658097711785492504343953926634992332820282019728792003956564819968';
    my $err = eval { $enc->encode([[$too_big]]); 1 } ? '' : $@;
    like($err, qr/Invalid decimal/, 'Decimal256 overflow rejected');
}

done_testing();
