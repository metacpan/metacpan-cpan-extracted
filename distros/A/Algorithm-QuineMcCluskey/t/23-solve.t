#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 2;

my($q, $eqn, @expected3_15, @expected3_18);

#
#    (AD) + (A'D') + (B) + (CD')
# or  (AC) + (AD) + (A'D') + (B)
#
@expected3_15 = (
	q/(AD) + (A'D') + (B) + (CD')/,
	q/(AC) + (AD) + (A'D') + (B)/
);

#
#    (AC'E') + (A'B'C') + (A'B'D'E) + (BCDE')
# or (AC'E') + (A'B'D'E) + (BCDE') + (B'C'E')
#
@expected3_18 = (
	q/(AC'E') + (A'B'C') + (A'B'D'E) + (BCDE')/,
	q/(AC'E') + (A'B'D'E) + (BCDE') + (B'C'E')/
);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Example 3.15 from Introduction to Logic Design, by Sajjan G. Shiva, page 123.",
	width => 4,
	minterms => [ 0, 2, 4 .. 6, 9, 10 ],
	dontcares => [7, 11 .. 15],
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected3_15)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Example 3.18 from Introduction to Logic Design, by Sajjan G. Shiva, page 131.",
	width => 5,
	minterms => [ 0, 1, 2, 5, 14, 16, 18, 24, 26, 30 ],
	dontcares => [3, 13, 28],
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected3_18)) == 1, $q->title);

