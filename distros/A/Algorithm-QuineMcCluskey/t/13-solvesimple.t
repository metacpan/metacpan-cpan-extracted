#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 1;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Example 3.16 from Introduction to Logic Design, by Sajjan G. Shiva, page 126.",
	width => 4,
	minterms => [ 0, 2, 5 .. 8, 10, 12 .. 15 ],
);

#
# Expected answers (all work to cover the terms).
#
@expected = (
	q/(AD') + (BD) + (B'D') + (CD')/,
	q/(AD') + (BC) + (BD) + (B'D')/,
	q/(AB) + (BC) + (BD) + (B'D')/,
	q/(AB) + (BD) + (B'D') + (CD')/
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

