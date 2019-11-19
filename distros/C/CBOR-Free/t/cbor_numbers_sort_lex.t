#!/usr/bin/env perl

# NB: This isn’t a test of CBOR::Free so much as validation of the assumption
# that underlies CBOR::Free’s implementation of canonical order.

use Test::More;
use Test::FailWarnings;
use Test::Differences;

use List::Util;

use CBOR::Free;

my @smallers = ( 0 .. 0x2000 );

my @largers = map { int rand 0xffffffff } ( 1 .. 100 );

my @numbers = List::Util::shuffle( @smallers, @largers );

my @sort_then_encode = map { CBOR::Free::encode($_) } sort { $a <=> $b } @numbers;

my @encode_then_sort = sort map { CBOR::Free::encode( 0 + $_ ) } @numbers;

eq_or_diff(
    \@sort_then_encode,
    \@encode_then_sort,
    'numbers: sort-then-encode is equivalent to encode-then-sort',
);

done_testing;
