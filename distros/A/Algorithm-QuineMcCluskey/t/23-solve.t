#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 1;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Example 3.15 from Introduction to Logic Design, by Sajjan G. Shiva, page 123.",
	width => 4,
	minterms => [ 0, 2, 4 .. 6, 9, 10 ],
	dontcares => [7, 11 .. 15],
);

#
#    (AD) + (A'D') + (B) + (CD')
# or  (AC) + (AD) + (A'D') + (B)
#
@expected = (
	q/(AD) + (A'D') + (B) + (CD')/,
	q/(AC) + (AD) + (A'D') + (B)/
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

