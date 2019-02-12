#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 4;

my($q, $eqn, @expected1st, @expected2nd, @expected3rd, @expected4th);

@expected1st = (
	q/(w) + (xy) + (xz)/
);

@expected2nd = (
	q/(w) + (xy) + (xz')/
);

@expected3rd = (
	q/(w) + (xy'z) + (x'y)/
);

@expected4th = (
	q/(z)/
);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "First column of a four bit binary to 2-4-2-1 (Aiken code) converter",
	width => 4,
	minterms => [ 5 .. 9 ],
	dontcares => [ 10 .. 15 ],
	vars => ['w' .. 'z'],
);

#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));
$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected1st)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Second column of a four bit binary to 2-4-2-1 (Aiken) converter",
	width => 4,
	minterms => [ 4, 6 .. 9 ],
	dontcares => [ 10 .. 15 ],
	vars => ['w' .. 'z'],
);

#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));
$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected2nd)) == 1, $q->title);


$q = Algorithm::QuineMcCluskey->new(
	title	=> "Third column of a four bit binary to 2-4-2-1 (Aiken code) converter",
	width => 4,
	minterms => [ 2, 3, 5, 8, 9 ],
	dontcares => [ 10 .. 15 ],
	vars => ['w' .. 'z'],
);

#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));
$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected3rd)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title	=> "Fourth column of a four bit binary to 2-4-2-1 (Aiken) converter",
	width => 4,
	minterms => [ 1, 3, 5, 7, 9 ],
	dontcares => [ 10 .. 15 ],
	vars => ['w' .. 'z'],
);

#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));
$eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected4th)) == 1, $q->title);

