#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 2;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title => "Column 1 of RPS problem",
	width  => 4,
	minterms => [ 6, 9, 11, 14 ],
	dontcares => [0..4, 8, 12],
	vars => [qw(a1 a0 b1 b0)],
);


#
#    (a0'b0) + (a0b0')/
#
@expected = (
	q/(a0b0') + (a0'b0)/,
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title => "Column 0 of RPS problem",
	width  => 4,
	minterms => [ 7, 11, 13, 14 ],
	dontcares => [0..4, 8, 12],
	vars => [qw(a1 a0 b1 b0)],
);

@expected = (
    q/(a1a0b1') + (a1a0b0') + (a1'b1b0) + (a0'b1b0)/,
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);


