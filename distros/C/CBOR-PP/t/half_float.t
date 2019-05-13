#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use CBOR::PP;

my @tests = (
    [ "\xf9\x00\x00" => 0 ],
    [ "\xf9\x80\x00" => ($^V lt v5.14) ? '-0' : 0 ],
    [ "\xf9\x3c\x00" => 1 ],
    [ "\xf9\x3e\x00" => 1.5 ],
    [ "\xf9\x7b\xff" => 65504 ],
    [ "\xf9\xc4\x00" => -4 ],
    [ "\xf9\x04\x00" => 0.00006103515625 ],
    [ "\xf9\x7c\x00" => unpack('f>', "\x7f\x80\x00\x00") ],
    [ "\xf9\x7e\x00" => unpack('f>', "\x7f\xc0\x00\x00") ],
    [ "\xf9\xfc\x00" => unpack('f>', "\xff\x80\x00\x00") ],
);

for my $t (@tests) {
    is(
        CBOR::PP::decode($t->[0]),
        $t->[1],
        sprintf('decode: %v02x => %s', @$t),
    );
}

done_testing;
