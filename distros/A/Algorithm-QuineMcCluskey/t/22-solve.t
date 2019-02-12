#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 1;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Five-bit, 12-minterm Boolean expression test with don't-cares",
	width => 5,
	minterms => [ 0, 5, 7, 8, 10, 11, 15, 17, 18, 23, 26, 27 ],
	dontcares => [ 2, 16, 19, 21, 24, 25 ]
);

@expected = (
	q/(AC') + (A'BDE) + (B'CE) + (C'E')/
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

