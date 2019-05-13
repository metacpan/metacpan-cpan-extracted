#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Data::Dumper;

use CBOR::PP;

my @roundtrip = (
    '00',
    '01',
    "\xff",
);

for my $val (@roundtrip) {
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;

    is(
        CBOR::PP::decode( CBOR::PP::encode($val) ),
        $val,
        "round-trip preserves: " . Dumper($val),
    );
}

#----------------------------------------------------------------------

is(
    unpack( 'H*', CBOR::PP::encode( CBOR::PP::tag(0, '2013-03-21T20:04:00Z') ) ),
    'c054323031332d30332d32315432303a30343a30305a',
    'encode a tagged string',
);

#----------------------------------------------------------------------

my $narcissus = [];
push @$narcissus, $narcissus;

throws_ok(
    sub { CBOR::PP::encode($narcissus) },
    'CBOR::PP::X::Recursion',
    'recursive object triggers recursion error',
);

my $a = [];
my $b = [$a];
push @$a, $b;

throws_ok(
    sub { CBOR::PP::encode($a) },
    'CBOR::PP::X::Recursion',
    'object that recurses with another object triggers recursion error',
);

done_testing();
