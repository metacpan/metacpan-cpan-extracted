#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 2;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title => "Solutions are more than 2**width in cost",
	width  => 4,
	minterms => [1, 3, 6, 7, 8, 10, 11, 13, 14],
	dontcares => [0, 4],
);

#
#
@expected = (
	q/(ABC'D) + (AB'C) + (AB'D') + (A'BC) + (A'B'D) + (BCD')/,
	q/(ABC'D) + (AB'D') + (A'BC) + (A'B'D) + (BCD') + (B'CD)/,
);

$eqn = $q->solve;

#diag(join("\n", $q->all_solutions()));

ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title => "Solutions are more than 2**width in cost",
	width  => 4,
	minterms => [0, 1, 5, 7, 8, 11, 13, 14],
	dontcares => [2, 6, 12],
);

#
#
@expected = (
	q/(ABD') + (AB'CD) + (A'BD) + (A'B'C') + (BC'D) + (B'C'D')/,
	q/(ABD') + (AB'CD) + (A'BD) + (A'C'D) + (BC'D) + (B'C'D')/,
	q/(AB'CD) + (A'BD) + (A'B'C') + (BCD') + (BC'D) + (B'C'D')/,
	q/(AB'CD) + (A'BD) + (A'C'D) + (BCD') + (BC'D) + (B'C'D')/,
);

$eqn = $q->solve;

#diag(join("\n", $q->all_solutions()));

ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

