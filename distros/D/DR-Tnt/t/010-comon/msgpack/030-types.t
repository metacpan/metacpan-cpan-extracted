#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 76;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Msgpack';
    use_ok 'DR::Tnt::Msgpack::Types', ':all';
    use_ok 'JSON::XS';
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


sub j($) {
    my ($o) = @_;
    JSON::XS
        -> new
        -> utf8
        -> allow_blessed
        -> convert_blessed

        -> encode($o)
    ;
}

isa_ok mp_true, DR::Tnt::Msgpack::Types::Bool::;
isa_ok mp_false, DR::Tnt::Msgpack::Types::Bool::;
isa_ok mp_bool(0), DR::Tnt::Msgpack::Types::Bool::;
isa_ok mp_bool(1), DR::Tnt::Msgpack::Types::Bool::;

isa_ok mp_int(123), DR::Tnt::Msgpack::Types::Int::;
isa_ok mp_string(123), DR::Tnt::Msgpack::Types::Str::;
isa_ok mp_blob(123), DR::Tnt::Msgpack::Types::Blob::;

can_ok mp_true, 'TO_JSON';
can_ok mp_false, 'TO_JSON';
can_ok mp_int(123), 'TO_JSON';
can_ok mp_string(123), 'TO_JSON';
can_ok mp_blob(123), 'TO_JSON';

is_deeply mp_int(123)->TO_JSON, 123, 'int->TO_JSON';
is_deeply mp_string('Hello')->TO_JSON, 'Hello', 'str->TO_JSON';
is_deeply mp_blob('Hello, world')->TO_JSON, 'Hello, world', 'blob->TO_JSON';

if (eval "require JSON::XS; 1") {
    is_deeply mp_true->TO_JSON, JSON::XS::true(), 'bool->TO_JSON';
    is_deeply mp_false->TO_JSON, JSON::XS::false(), 'bool->TO_JSON';
} elsif (eval "require JSON; 1") {
    is_deeply mp_true->TO_JSON, JSON::true(), 'bool->TO_JSON';
    is_deeply mp_false->TO_JSON, JSON::false(), 'bool->TO_JSON';
}


is j(mp_true), 'true', 'json encode';
is j(mp_false), 'false', 'json encode';

