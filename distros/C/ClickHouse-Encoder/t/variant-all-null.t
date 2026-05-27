#!/usr/bin/env perl
# Variant column where every row is undef (wire disc = 255). Edge
# case for the count-by-variant pass that's easy to break: empty
# sub-column inputs, no Variant data section, only the per-row disc
# byte stream of 0xff.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my $enc = ClickHouse::Encoder->new(columns =>
    [['v','Variant(Int32, String)']]);

# All-NULL Variant: every row is undef
{
    my $bytes = $enc->encode([[undef], [undef], [undef]]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    my @rows  = @{ $blk->{columns}[0]{values} };
    is(scalar @rows, 3, 'three rows decoded');
    ok(!defined $rows[0], 'row 0 undef');
    ok(!defined $rows[1], 'row 1 undef');
    ok(!defined $rows[2], 'row 2 undef');
}

# Single-row all-NULL Variant
{
    my $bytes = $enc->encode([[undef]]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    is(scalar @{ $blk->{columns}[0]{values} }, 1, 'one-row block');
    ok(!defined $blk->{columns}[0]{values}[0], 'lone row is undef');
}

# Zero-row Variant (just the column header, no body): the streamer
# shouldn't blow up on an empty batch.
{
    my $bytes = $enc->encode([]);
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    is($blk->{nrows}, 0, 'zero-row block decoded');
}

# Mixed NULL and non-NULL: pins that the count-by-variant pass
# correctly handles the disc=255 rows alongside disc=0/1 rows.
{
    my $bytes = $enc->encode([
        [undef], [[0, 42]], [undef], [[1, 'hi']], [undef],
    ]);
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    my @rows = @{ $blk->{columns}[0]{values} };
    is(scalar @rows, 5, 'mixed: five rows decoded');
    ok(!defined $rows[0], 'mixed: row 0 undef');
    ok(!defined $rows[2], 'mixed: row 2 undef');
    ok(!defined $rows[4], 'mixed: row 4 undef');
    is_deeply($rows[1], [0, 42],   'mixed: row 1 = Int32 variant');
    is_deeply($rows[3], [1, 'hi'], 'mixed: row 3 = String variant');
}

done_testing();
