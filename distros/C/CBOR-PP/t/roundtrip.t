#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use CBOR::PP;

my $cbor = "cabc";
my $dec = CBOR::PP::decode($cbor);
my $cbor2 = CBOR::PP::encode($dec);

is($cbor2, $cbor, 'round-trip ASCII text string preserves text typing' );

done_testing;
