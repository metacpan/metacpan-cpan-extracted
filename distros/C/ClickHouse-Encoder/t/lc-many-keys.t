#!/usr/bin/env perl
# Pin the LowCardinality index-width transitions: 0..256 distinct
# entries use UInt8 indices (idx_type=0), 257..65536 use UInt16
# (idx_type=1), 65537..2^32 use UInt32 (idx_type=2). The smaller-dict
# cases are covered by other tests; this one drives each transition.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Test::More;
use ClickHouse::Encoder;
use TestCH qw(skip_header);

# Extract idx_type from the LC header bytes:
#   8 bytes version (=1) + 8 bytes flags. Low byte of flags is idx_type.
sub idx_type_of {
    my ($bin, $hdr_off) = @_;
    my $flags = unpack 'Q<', substr($bin, $hdr_off + 8, 8);
    return $flags & 0xff;
}

# Slot 0 is always reserved (empty-string sentinel for non-Nullable;
# null sentinel for Nullable). So 255 distinct user strings gives
# dict_count = 256, fitting UInt8 indices (0..255).
{
    my @vals = map { sprintf("k%03d", $_) } 0 .. 254;
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'LowCardinality(String)']]);
    my $bin = $enc->encode([map { [$_] } @vals]);
    my $off = skip_header($bin);
    is(idx_type_of($bin, $off), 0,
       '255 distinct + slot 0 = 256 dict entries: idx_type = 0 (UInt8)');
}

# 256 distinct user strings -> dict_count = 257, just past the UInt8
# boundary, must promote to UInt16.
{
    my @vals = map { sprintf("k%05d", $_) } 0 .. 255;
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'LowCardinality(String)']]);
    my $bin = $enc->encode([map { [$_] } @vals]);
    my $off = skip_header($bin);
    is(idx_type_of($bin, $off), 1,
       '256 distinct + slot 0 = 257 dict entries: idx_type = 1 (UInt16)');
}

# 65536 distinct values: dict_count = 65536 (still UInt16-addressable
# since indices go 0..65535).
{
    my @vals = map { sprintf("k%06d", $_) } 0 .. 65534;  # 65535 distinct
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'LowCardinality(String)']]);
    my $bin = $enc->encode([map { [$_] } @vals]);
    my $off = skip_header($bin);
    is(idx_type_of($bin, $off), 1,
       '65535 distinct values: idx_type = 1 (UInt16) -- right below the UInt32 boundary');
}

# Index *data* width sanity-check: 257 distinct values forces 2-byte
# indices, so a 100-row block with 257-distinct dict has indices
# section = 100*2 = 200 bytes. We don't grep the exact byte layout
# (varint flexibility, dict body varies); just confirm the index_type
# byte is what we expected so callers don't silently emit a UInt8-
# truncated index for a >256-entry dict.
{
    my @rows = map { ['x' . ($_ % 300)] } 1 .. 1000;  # 300 distinct
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'LowCardinality(String)']]);
    my $bin = $enc->encode(\@rows);
    my $off = skip_header($bin);
    is(idx_type_of($bin, $off), 1,
       '1000 rows with 300 distinct: UInt16 indices (no UInt8 truncation)');
}

# LowCardinality(Nullable(String)) with many keys: same transitions,
# but dict slot 0 is the null sentinel (not user-supplied).
{
    my @vals = map { sprintf("u%05d", $_) } 0 .. 300;
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'LowCardinality(Nullable(String))']]);
    my $bin = $enc->encode([[undef], map { [$_] } @vals]);
    my $off = skip_header($bin);
    is(idx_type_of($bin, $off), 1,
       'LC(Nullable(String)) with 301+null distinct: UInt16 indices');
}

done_testing();
