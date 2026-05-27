#!/usr/bin/env perl
# Exercise String values at varint length-prefix boundaries. The wire
# format prefixes each String with a varint length: bytes <128 use 1
# byte, <16384 use 2 bytes, <2_097_152 use 3 bytes, etc. Off-by-one in
# varint encoding only manifests when the length crosses a boundary, so
# we explicitly hit the 1-/2-/3-/4-byte transition points.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Test::More;
use ClickHouse::Encoder;
use TestCH qw(read_varint_ref skip_header);
*read_varint = \&read_varint_ref;

my $enc = ClickHouse::Encoder->new(columns => [['v', 'String']]);

for my $len (1, 127, 128, 16383, 16384, 2_097_151, 2_097_152) {
    my $payload = 'x' x $len;
    my $bin     = $enc->encode([[$payload]]);
    my $off     = skip_header($bin);
    my $got_len = read_varint(\$bin, \$off);
    is($got_len, $len, "String length $len encodes via varint correctly");
    is(substr($bin, $off, 16), substr($payload, 0, 16),
       "String length $len bytes start with the expected payload");
    is(length($bin) - $off, $len,
       "String length $len: data section is exactly $len bytes");
}

# FixedString(N) doesn't use varint -- just N raw bytes -- but it shares
# the buf_grow path; sanity-check a large FixedString.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'FixedString(65536)']]);
    my $bin = $enc->encode([['z' x 65536]]);
    my $off = skip_header($bin);
    is(length($bin) - $off, 65536, 'FixedString(65536) emits exactly 64KiB');
    is(substr($bin, -1), 'z', 'FixedString(65536) last byte is payload');
}

done_testing();
