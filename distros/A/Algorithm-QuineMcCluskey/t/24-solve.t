#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 3;

my($q, $eqn, @expected);

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


$q = Algorithm::QuineMcCluskey->new(
	title => "Problem to test the covered_least() function",
	width  => 6,
	minterms => [1..14, 32..35, 40..44, 60..63],
	dontcares => [48, 56],
	vars => [qw(u v w x y z)],
);

#
# All solutions
#
@expected = (
    q/(uvwx) + (uv'x') + (u'v'w'x) + (u'v'xz') + (u'v'y'z) + (v'wy'z') + (v'x'y)/,
    q/(uvwx) + (uv'x') + (u'v'w'y) + (u'v'xz') + (u'v'y'z) + (v'wy'z') + (v'x'y)/,
    q/(uvwx) + (uv'x') + (u'v'w'z) + (u'v'xy') + (u'v'yz') + (v'wy'z') + (v'x'y)/,
    q/(uvwx) + (uv'x') + (u'v'w'z) + (u'v'xy') + (u'v'yz') + (v'wy'z') + (v'x'z)/,
    q/(uvwx) + (uv'x') + (u'v'w'x) + (u'v'xy') + (u'v'yz') + (v'wy'z') + (v'x'z)/,

);

$eqn = $q->solve;
#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));

ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

