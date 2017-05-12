#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 1;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Example 3.17 from Introduction to Logic Design, by Sajjan G. Shiva, page 130.",
	width => 3,
	minterms => [ 0, 1, 3, 4, 6, 7 ],
);

@expected = (
	q/(AC') + (A'B') + (BC)/,
	q/(AB) + (A'C) + (B'C')/
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

