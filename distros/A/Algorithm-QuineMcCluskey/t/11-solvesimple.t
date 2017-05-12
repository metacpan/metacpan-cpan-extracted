#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 2;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title	=> 'Four-bit, 8-minterm Boolean expression test',
	width => 4,
	minterms => [ 1, 3, 7, 11, 12, 13, 14, 15 ]
);

@expected = (
	q/(AB) + (A'B'D) + (CD)/
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title	=> 'a xor c xor d test',
	width => 4,
	minterms => [ 1, 2, 5, 6, 8, 11, 12, 15 ]
);

@expected = (
	q/(ACD) + (AC'D') + (A'CD') + (A'C'D)/
);

$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

