#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 1;

my($q, $eqn, @expected);

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


