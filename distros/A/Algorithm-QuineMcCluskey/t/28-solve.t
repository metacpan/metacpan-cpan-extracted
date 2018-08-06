#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 3;

my($q, $eqn, @expected);

$q = Algorithm::QuineMcCluskey->new(
	title => "Column 2 of RPS7 problem",
	width  => 6,
	minterms => [13, 14, 20, 22, 23, 28, 29, 31, 33, 37..39,
			 42, 44, 46, 47, 51..53, 55, 57, 60..62],
	dontcares => [0..8, 16, 24, 32, 40, 48, 56],
	vars => [qw(a2 a1 a0 b2 b1 b0)],
);


#
# All solutions for RPS7 column 2.
#
@expected = (
    q/(a2a1a0b1') + (a2a1a0'b1b0) + (a2a1b2b1') + (a2a1'a0b0') + (a2a1'b2b1) + (a2a0b2b0') + (a2'a1b2b1b0) + (a2'a0b2b1'b0) + (a2'a0'b2b0') + (a1b1'b0') + (a1'a0'b1'b0) + (a1'b2b1b0')/,
    q/(a2a1a0b1') + (a2a1a0'b1b0) + (a2a1b2b1') + (a2a1'a0b0') + (a2a1'b2b1) + (a2a0b2b0') + (a2'a1b2b1b0) + (a2'a0b2b1'b0) + (a2'a0'b2b1) + (a1b1'b0') + (a1'a0'b1'b0) + (a1'b2b1b0')/,
);

$eqn = $q->solve;
#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));

ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title => "Column 1 of RPS7 problem",
	width  => 6,
	minterms => [ 10, 11, 14, 19, 21..23, 26, 30, 31, 34, 35, 38,
			  43, 46, 47, 50, 51, 55, 57..60, 62],
	dontcares => [0..8, 16, 24, 32, 40, 48, 56],
	vars => [qw(a2 a1 a0 b2 b1 b0)],
);

#
# All solutions for RPS7 column 1.
#
@expected = (
    q/(a2a1a0b2') + (a2a1a0b0') + (a2a1'a0b1b0) + (a2a0'b2'b1) + (a2'a1b2b1) + (a2'a0b1b0') + (a2'a0'b2b0) + (a1a0'b1b0) + (a1'b2b1b0') + (a1'b2'b1b0)/,
    q/(a2a1a0b2') + (a2a1a0b0') + (a2a1'a0b2b1) + (a2a0'b2'b1) + (a2'a1b2b1) + (a2'a0b1b0') + (a2'a0'b2b0) + (a1a0'b1b0) + (a1'b2b1b0') + (a1'b2'b1b0)/
);

$eqn = $q->solve;
#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));

ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);



$q = Algorithm::QuineMcCluskey->new(
	title => "Column 0 of RPS7 problem",
	width  => 6,
	minterms => [ 11..13, 15, 17, 19, 23, 25, 29..31, 35, 37,
			  41..43, 47, 49, 53, 55, 57, 59..61],
	dontcares => [0..8, 16, 24, 32, 40, 48, 56],
	vars => [qw(a2 a1 a0 b2 b1 b0)],
);

#
# All solutions for RPS7 column 0.
#
@expected = (
    q/(a2a1a0b1') + (a2a1'a0b2') + (a2a0b2'b0) + (a2a0'b2b1'b0) + (a2'a1a0b2b1) + (a2'a1'b2b1') + (a2'a0'b2'b0) + (a1a0b1'b0) + (a1a0'b2b1b0) + (a1b2'b1') + (a1'a0b1b0) + (a1'b2'b1b0)/,
    q/(a2a1a0b1') + (a2a1'a0b2') + (a2a0b2'b0) + (a2a0'b2b1'b0) + (a2'a1a0b2b1) + (a2'a1'b2b1') + (a2'a0'b1b0) + (a1a0b1'b0) + (a1a0'b2b1b0) + (a1b2'b1') + (a1'a0b1b0) + (a1'b2'b1b0)/,
);

$eqn = $q->solve;
#diag(join("\n", $q->title, "All solutions", $q->all_solutions()));

ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);


