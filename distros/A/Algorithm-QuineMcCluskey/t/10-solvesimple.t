#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 2;

my($q, $eqn, @expected);

#
# Now the case where every possible item
# is covered with minterms. The return value
# should simply be (1).
#
@expected = (
	q/(1)/,
);

$q = Algorithm::QuineMcCluskey->new(
	title => "All terms covered with minterms",
	width  => 4,
	minterms => [ 0 .. 15],
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
	title => "All terms covered with maxterms",
	width  => 4,
	maxterms => [ 0 .. 15],
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

