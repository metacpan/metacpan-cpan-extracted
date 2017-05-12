#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 57;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Msgpack';
}

is msgunpack(msgpack(undef)), undef, 'undef';
for (0, 0x7E, 0x7F) {
    is msgunpack(msgpack($_)), $_, "num $_";
}
for (0x7F + 1, 0xFE, 0xFF) {
    is msgunpack(msgpack($_)), $_, "num $_";
}
for (0xFF + 1, 0xFFFE, 0xFFFF) {
    is msgunpack(msgpack($_)), $_, "num $_";
}
for (0xFFFF + 1, 0xFFFF_FFFE, 0xFFFF_FFFF) {
    is msgunpack(msgpack($_)), $_, "num $_";
}
for (0xFFFF_FFFF + 1, 0xFFFF_FFFF * 25) {
    is msgunpack(msgpack($_)), $_, "num $_";
}
for (-1, -0x1F, -0x20) {
    is msgunpack(msgpack($_)), $_, "num $_";
}
for (-0x21, -0x7FF, -0x7FF - 1, -0x7FFF - 2) {
    is msgunpack(msgpack($_)), $_, "num $_";
}
for (-0x7FFF - 2, -0x7FFF_FFFF, -0x7FFF_FFFF * 2, -0x7FFF_FFFF * 25) {
    is msgunpack(msgpack($_)), $_, "num $_";
}

for ('', 'h', 'hello', 'x' x 0x1F) {
    is msgunpack(msgpack($_)), $_, "str $_";
    is length(msgpack $_), 1 + length $_, 'msgpack length';
}

for ('x' x 0x20, 'x' x 0xFF) {
    is msgunpack(msgpack($_)), $_, "str " . length $_;
    is length(msgpack $_), 2 + length $_, 'msgpack length';
}

for ('x' x 0x100, 'x' x 0xFFFF) {
    is msgunpack(msgpack($_)), $_, "str " . length $_;
    is length(msgpack $_), 3 + length $_, 'msgpack length';
}

for ('x' x 0x10000) {
    is msgunpack(msgpack($_)), $_, "str " . length $_;
    is length(msgpack $_), 5 + length $_, 'msgpack length';
}

for ('привет', 'медвед') {
    my $us = encode utf8 => $_;

    is msgunpack(msgpack($_)), $us, "no utf8 str '$_'";
    is msgunpack_utf8(msgpack($_)), $_, "utf8 str '$_'";
}

for ([], [0], [1], [1 .. 0xF]) {
    is_deeply msgunpack(msgpack($_)), $_, "fix array " . @$_;
}
for ({}, {0 .. 1}, { map { ($_, $_) } 1 .. 0xF }) {
    is_deeply msgunpack(msgpack($_)), $_, "fix hash " . keys %$_;
}


note 'big object';
my $o = {
    (0x00)              => 1,
    (0xFF)              => 2,
    (0xFFFF)            => 3,
    (0xFFFF_F)          => 4,
    (0xFFFF_FFFF)       => 5,
    (0xFFFF_FFFF + 1)   => 6,
    
    (-0x01)             => 1,
    (-0xFF)             => 2,
    (-0xFFFF)           => 3,
    (-0xFFFF_F)         => 4,
    (-0xFFFF_FFFF)      => 5,
    (-0xFFFF_FFFF - 7)  => 6,

    fixarray0           => [],
    fixarrayF           => [ 1 .. 0xF ],

    fixhash0            => {},
    fixhashF            => { map { ($_ => $_ ** $_) } 1 .. 0xF },
    double              => 3.1415927,

    fixstr              => '',
    fixstrmax           => ('x' x 0x1F),
    str8                => ('x' x 0xFF),
    str16               => ('x' x 0xF000),
    str32               => ('x' x 0x10000),
    unicode             => { 'привет' => 'медвед' },

    deep    => [
        1 .. 10,
        {
            a => {
                b  => [
                    c => [
                        d => {
                            e => {
                                f => 'g'
                            }
                        }
                    ]
                ]
            }
        }
    ]
};

is_deeply msgunpack_utf8(msgpack($o)), $o, 'o = msgunpack msgpack o';
