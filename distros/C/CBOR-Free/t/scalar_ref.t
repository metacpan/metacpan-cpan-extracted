#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Data::Dumper;

use_ok('CBOR::Free');

# Example taken from http://cbor.schmorp.de/indirection
my $canonical = pack( 'C*', 0x82, 0x80, 0xd9, 0x56, 0x52, 0x66, ) . 'string';

my $decoded = CBOR::Free::decode($canonical);

is_deeply(
    $decoded,
    [ [], \'string' ],
    'decode a string reference (from specification)',
);

my $all_types_ar = [ \undef, \0, \1, \'haha', \[], \{}, \do { \[] } ];

my $round_tripped = CBOR::Free::decode( CBOR::Free::encode($all_types_ar, scalar_references => 1) );

is_deeply(
    $round_tripped,
    $all_types_ar,
    'round-trip scalar references',
);

done_testing;
