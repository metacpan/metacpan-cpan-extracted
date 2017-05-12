#!perl -T
use strict;
use Test::More;

my $n = 4;
plan tests => 3 + $n;

use_ok( "Acme::MetaSyntactic", "daleks" );

my @words = eval { metadaleks($n) };
is( $@, "", "metadaleks($n)" );
is( scalar @words, $n, "we want $n words" );

for my $word (@words) {
    cmp_ok( length $word, ">=", 1, "word must be non empty" );
}
