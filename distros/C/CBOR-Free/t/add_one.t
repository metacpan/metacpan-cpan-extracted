#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok('CBOR::Free::AddOne');

my $maxlen = (length pack 'L!') > 4 ? 19 : 9;

for (1 .. 100) {
    my $len = 1 + int rand $maxlen;

    my $int = 0 + join( q<>, map { int rand 10 } 1 .. $len );

    next if $int == ~0;
    next if $int == 0xffffffff;

    is(
        1 + $int,
        CBOR::Free::AddOne::to_nonnegative_integer($int),
        "to_nonnegative_integer($int)",
    );
}

is(
    CBOR::Free::AddOne::to_nonnegative_integer('18446744073709551615'),
    '18446744073709551616',
    'max u64',
);

is(
    CBOR::Free::AddOne::to_nonnegative_integer(0xffffffff),
    '4294967296',
    'max u32',
);

done_testing();
