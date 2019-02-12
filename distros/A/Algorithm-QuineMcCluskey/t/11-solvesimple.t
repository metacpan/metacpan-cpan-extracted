#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 4;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title	=> 'a xor c xor d minterms test',
	width => 4,
	minterms => [ 1, 2, 5, 6, 8, 11, 12, 15 ]
);

@expected = (
	q/(ACD) + (AC'D') + (A'CD') + (A'C'D)/
);

#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));
$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title	=> 'a xor c xor d maxterms test',
	width => 4,
	maxterms => [ 0, 3, 4, 7, 9, 10, 13, 14 ]
);

@expected = (
	q/(A' + C' + D)(A' + C + D')(A + C' + D')(A + C + D)/
);

#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));
$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);


$q = Algorithm::QuineMcCluskey->new(
	title	=> 'Four-bit, 8-minterm Boolean expression test',
	width => 4,
	minterms => [ 1, 3, 7, 11, 12, 13, 14, 15 ]
);

@expected = (
	q/(AB) + (A'B'D) + (CD)/
);

#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));
$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title	=> 'Four-bit, 8-maxterm Boolean expression test',
	width => 4,
	maxterms => [ 0, 2, 4, 5, 6, 8, 9, 10 ]
);

@expected = (
	q/(A' + B + C)(A + B' + C)(A + D)(B + D)/
);

#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));
$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

