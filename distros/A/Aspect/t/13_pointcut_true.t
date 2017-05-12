#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Test::NoWarnings;
use Aspect;

my $COUNT = 0;

sub foo {
	$COUNT += 1
}

# Set up a simple permanent advice
before {
	$COUNT += 10
} call 'main::foo'
& true { $COUNT == 1 };

is( foo(),  1, 'Advice did not fire' );
is( foo(), 12, 'Advice did fired'    );
is( foo(), 13, 'Advice did not fire' );
