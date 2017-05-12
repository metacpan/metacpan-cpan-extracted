#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;
use Aspect;

my $COUNT = 0;

sub foo {
	$COUNT += 1;
	return if $COUNT > 13;
	foo();
}

# Set up a simple permanent advice
around {
	$COUNT += 10;
	$_[0]->proceed;
} call 'main::foo'
& highest;

foo();

# At the end of the recursive call, did the advice only fire once?
is( $COUNT, 14, 'Advice fired once' );
