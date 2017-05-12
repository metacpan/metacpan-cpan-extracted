#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 2;

my($q, $eqn, @expected);

#
# The case where every possible item
# is covered with minterms. The return value
# should simply be (1).
#
@expected = (
	q/(1)/,
);

$q = Algorithm::QuineMcCluskey->new(
	title => "All terms covered, minterms and dontcares",
	width  => 4,
	minterms => [ 4, 7, 9, 10, 11, 14 ],
	dontcares => [0..3, 5, 6, 8, 12, 13, 15],
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

#
# Now the case where every possible item
# is covered with maxterms. The return value
# should simply be (0).
#
@expected = (
	q/(0)/,
);

$q = Algorithm::QuineMcCluskey->new(
	title => "All terms covered, maxterms and dontcares",
	width  => 4,
	maxterms => [ 4, 7, 9, 10, 11, 14 ],
	dontcares => [0..3, 5, 6, 8, 12, 13, 15],
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

