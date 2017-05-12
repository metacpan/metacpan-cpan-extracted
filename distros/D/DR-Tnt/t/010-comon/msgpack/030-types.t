#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 56;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Msgpack';
    use_ok 'DR::Tnt::Msgpack::Types', ':all';
}

is msgpack(mp_bool(1)), pack('C', 0xC3), 'true';
is msgpack(mp_bool(0)), pack('C', 0xC2), 'false';

for ('', 'hello', 'вася', 123, -1) {
    my $s = $_;
    utf8::encode $s;
    is msgpack(mp_string($_)),
        pack('Ca*', 0xA0 | length $s, $s),
        "str '$_'";
    is msgunpack(msgpack(mp_string $_)), $s, 'msgunpack str';
    is msgunpack_utf8(msgpack(mp_string $_)), $_, 'msgunpack str';
    
    is msgpack(mp_blob($_)),
        pack('CC/a*', 0xC4, $s),
        "blob '$_'";
}

for ('1', '1' x 0x1F, '1' x 0xFF, '1' x 0xFFFF, '1' x 0xF_FFFF) {
    is msgunpack(msgpack(mp_string($_))), $_, 'pack string len ' . length $_;
    is msgunpack(msgpack(mp_blob($_))), $_, 'pack blob len ' . length $_;
}

for (0, 0x1F, 0x7F, 0xFF, 0x7FFF, 0xFFFF, 0x7FFF_FFFF, 0xFFFF_FFFF) {
    is msgunpack(msgpack(mp_int $_)), $_, 'pack mp_int ' . $_;
    is msgunpack(msgpack(mp_int $_ + 1)), $_ + 1, 'pack mp_int ' . ($_ + 1);
}

isa_ok mp_true, DR::Tnt::Msgpack::Types::Bool::, 'bool';
isa_ok mp_false, DR::Tnt::Msgpack::Types::Bool::, 'bool';
is ${ mp_true() }, 1, 'true';
is ${ mp_true() }, 1, 'false';

is_deeply msgunpack(msgpack mp_true), mp_true, 'pack true';
is_deeply msgunpack(msgpack mp_false), mp_false, 'pack false';
