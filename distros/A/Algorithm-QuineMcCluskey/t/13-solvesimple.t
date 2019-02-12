#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 2;

my($q, $eqn, @expected3_16, @expected3_17);

#
# Expected answers (all work to cover the terms).
#
@expected3_16 = (
	q/(AD') + (BD) + (B'D') + (CD')/,
	q/(AD') + (BC) + (BD) + (B'D')/,
	q/(AB) + (BC) + (BD) + (B'D')/,
	q/(AB) + (BD) + (B'D') + (CD')/
);

@expected3_17 = (
	q/(AC') + (A'B') + (BC)/,
	q/(AB) + (A'C) + (B'C')/
);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Example 3.16 from Introduction to Logic Design, by Sajjan G. Shiva, page 126.",
	width => 4,
	minterms => [ 0, 2, 5 .. 8, 10, 12 .. 15 ],
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected3_16)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Example 3.17 from Introduction to Logic Design, by Sajjan G. Shiva, page 130.",
	width => 3,
	minterms => [ 0, 1, 3, 4, 6, 7 ],
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected3_17)) == 1, $q->title);

