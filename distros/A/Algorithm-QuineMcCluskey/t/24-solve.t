#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 3;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Example 3.18 from Introduction to Logic Design, by Sajjan G. Shiva, page 131.",
	width => 5,
	minterms => [ 0, 1, 2, 5, 14, 16, 18, 24, 26, 30 ],
	dontcares => [3, 13, 28],
);

#
#    (AC'E') + (A'B'C') + (A'B'D'E) + (BCDE')
# or (AC'E') + (A'B'D'E) + (BCDE') + (B'C'E')
#
@expected = (
	q/(AC'E') + (A'B'C') + (A'B'D'E) + (BCDE')/,
	q/(AC'E') + (A'B'D'E) + (BCDE') + (B'C'E')/
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title => "A problem with four possible covers",
	width  => 4,
	minterms => [ 1, 2, 8, 9, 14, 15 ],
	dontcares => [5, 6, 10, 13],
);

#
#    (ABD) + (AB'C') + (CD') + (C'D)
# or (ABC) + (AB'C') + (CD') + (C'D)
# or (ABD) + (AB'D') + (CD') + (C'D)
# or (ABC) + (AB'D') + (CD') + (C'D)
#
@expected = (
	q/(ABD) + (AB'C') + (CD') + (C'D)/,
	q/(ABC) + (AB'C') + (CD') + (C'D)/,
	q/(ABD) + (AB'D') + (CD') + (C'D)/,
	q/(ABC) + (AB'D') + (CD') + (C'D)/,
);

$eqn = $q->solve;

#diag("solution: \"" . $eqn . "\"\n");
#diag("\nall solutions:\n\"" . join("\"\n\"", $q->all_solutions()) . "\"\n\n");

ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title => "A problem with sixteen possible covers",
	width  => 4,
	minterms => [ 4, 7, 8, 13 ],
	dontcares => [2, 3, 6, 10, 11, 12, 15],
);


#
# The sixteen possible solutions. Gaze in wonder.
#
@expected = (
	q/(ABC') + (AB'D') + (A'BD') + (A'C)/,
	q/(ABC') + (AB'D') + (A'BD') + (CD)/,
	q/(ABC') + (AB'D') + (A'C) + (BC'D')/,
	q/(ABC') + (AB'D') + (BC'D') + (CD)/,
	q/(ABC') + (AC'D') + (A'BD') + (A'C)/,
	q/(ABC') + (AC'D') + (A'BD') + (CD)/,
	q/(ABC') + (AC'D') + (A'C) + (BC'D')/,
	q/(ABC') + (AC'D') + (BC'D') + (CD)/,
	q/(ABD) + (AB'D') + (A'BD') + (A'C)/,
	q/(ABD) + (AB'D') + (A'BD') + (CD)/,
	q/(ABD) + (AB'D') + (A'C) + (BC'D')/,
	q/(ABD) + (AB'D') + (BC'D') + (CD)/,
	q/(ABD) + (AC'D') + (A'BD') + (A'C)/,
	q/(ABD) + (AC'D') + (A'BD') + (CD)/,
	q/(ABD) + (AC'D') + (A'C) + (BC'D')/,
	q/(ABD) + (AC'D') + (BC'D') + (CD)/,
);

$eqn = $q->solve;

#diag("solution: \"" . $eqn . "\"\n");
#diag("\nall solutions:\n\"" . join("\"\n\"", $q->all_solutions()) . "\"\n\n");

ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);


