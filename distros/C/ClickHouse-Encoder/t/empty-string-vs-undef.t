#!/usr/bin/env perl
# Discrimination between empty-string '' and undef across String /
# Nullable(String) / Nullable(FixedString) / LowCardinality(...)
# Pin both encode bytes and decode round-trip so the semantics
# survive any refactor.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Naked String: both undef and '' encode to an empty string on the
# wire. Decode produces '' for both (CH itself has no notion of
# "null String"; only Nullable(String) does).
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','String']]);
    my $bytes = $enc->encode([[''], [undef]]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    is_deeply($blk->{columns}[0]{values}, ['', ''],
              'String: undef encodes as "" (no Null in plain String)');
}

# Nullable(String): '' and undef are DIFFERENT.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Nullable(String)']]);
    my $bytes = $enc->encode([[''], [undef], ['x']]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    my @vals  = @{ $blk->{columns}[0]{values} };
    is($vals[0], '',    'Nullable(String): "" round-trip');
    ok(!defined $vals[1], 'Nullable(String): undef round-trip');
    is($vals[2], 'x',   'Nullable(String): "x" round-trip');
}

# Nullable(FixedString(4)): same discrimination, but '' pads with NUL.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Nullable(FixedString(4))']]);
    my $bytes = $enc->encode([['ab'], [undef], ['']]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    my @vals  = @{ $blk->{columns}[0]{values} };
    is($vals[0], "ab\0\0", 'Nullable(FixedString): non-empty padded');
    ok(!defined $vals[1],  'Nullable(FixedString): undef preserved');
    is($vals[2], "\0\0\0\0", 'Nullable(FixedString): "" is all NULs');
}

# LowCardinality(String): undef and '' both encode to the empty-string
# sentinel at dict slot 0 (CH stores no Null in plain LC(String)).
{
    my $enc = ClickHouse::Encoder->new(columns =>
        [['v','LowCardinality(String)']]);
    my $bytes = $enc->encode([['x'], [''], [undef]]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    my @vals  = @{ $blk->{columns}[0]{values} };
    is($vals[0], 'x', 'LC(String): "x" round-trip');
    is($vals[1], '',  'LC(String): "" round-trip');
    is($vals[2], '',  'LC(String): undef -> "" (no Null slot in non-Nullable LC)');
}

# LowCardinality(Nullable(String)): full discrimination - "" and undef
# go to different dict slots (slot 0 = null sentinel; "" is a real
# user value at some later slot).
{
    my $enc = ClickHouse::Encoder->new(columns =>
        [['v','LowCardinality(Nullable(String))']]);
    my $bytes = $enc->encode([[''], [undef], ['x'], ['']]);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    my @vals  = @{ $blk->{columns}[0]{values} };
    is($vals[0], '',     'LC(Nullable(String)): "" round-trip');
    ok(!defined $vals[1], 'LC(Nullable(String)): undef preserved');
    is($vals[2], 'x',    'LC(Nullable(String)): "x" round-trip');
    is($vals[3], '',     'LC(Nullable(String)): repeated "" coalesces to same slot');
}

done_testing();
