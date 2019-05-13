#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use CBOR::PP;

my $str = CBOR::PP::decode("\x64éé");

ok(
    utf8::is_utf8($str),
    'UTF-8 string is decoded as such',
);

$str = CBOR::PP::decode("\x44éé");

ok(
    !utf8::is_utf8($str),
    'binary string is decoded as such',
);

$str = pack 'U', 0xfc;
is(
    sprintf('%v.02x', CBOR::PP::encode($str)),
    '62.c3.bc',
    'Encode UTF-8 U+00fc (ü)',
);

$str = "\xc3\xbc";
is(
    sprintf('%v.02x', CBOR::PP::encode($str)),
    '42.c3.bc',
    'Encode non-UTF-8 U+00fc (ü)',
);

done_testing();
