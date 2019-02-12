#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey::Util qw(row_dominance);


#
# Testing code starts here
#

use Test::More tests => 5;

my @rows;
my @expected_rows;

#
# Example 3.17 from Introduction to Logic Design, p. 130.
#
my %primes = (
	'00x' => [ '000', '001' ],
	'x00' => [ '000', '100' ],
	'0x1' => [ '001', '011' ],
	'1x0' => [ '100', '110' ],
	'x11' => [ '011', '111' ],
	'11x' => [ '011', '111' ],
);

@expected_rows = qw();	# I.e., no rows dominate others.
@rows = row_dominance(\%primes, 0);
is_deeply(\@rows, \@expected_rows, "Dominant rows 1");


#
# Example 3.18 from Introduction to Logic Design, p. 131.
# (After the essential prime implicant is removed.)
#
%primes = (
	'11xx0' => [ '11000', '11010' ],
	'1x0x0' => [ '10000', '10010', '11000', '11010' ],
	'x00x0' => [ '00000', '00010', '10000', '10010' ],
	'000xx' => [ '00000', '00001', '00010', '00011' ],
	'0x101' => [ '00101' ],
	'00x01' => [ '00001', '00101' ],
);

@expected_rows = sort qw(11xx0 0x101);
@rows = sort(row_dominance(\%primes, 1));
is_deeply(\@rows, \@expected_rows, "Dominated rows 2");

@expected_rows = sort qw(1x0x0 00x01);
@rows = sort(row_dominance(\%primes, 0));
is_deeply(\@rows, \@expected_rows, "Dominant rows 2a");

#
#
#
%primes = (
	'000x' => [ '0000', '0001' ],
	'x00x' => [ '0000', '0001', '1000' ],
	'101x' => [ '0010', '0011', '1011' ],
	'10xx' => [ '0011', '1000', '1001', '1011' ],
	'1xxx' => [ '0011', '1000', '1001', '1011' ],
);

@expected_rows = sort qw(x00x);
@rows = sort(row_dominance(\%primes, 0));
is_deeply(\@rows, \@expected_rows, "Dominant rows 3");

%primes = (
	'x101x' => [ '01011', '11011' ],
	'0x111' => [ '01111' ],
	'01x11' => [ '01011', '01111' ],
	'1x0xx' => [ '10001', '11011' ],
	'10xx1' => [ '10001' ],
);

@expected_rows = sort qw(01x11 1x0xx);
@rows = sort(row_dominance(\%primes, 0));
is_deeply(\@rows, \@expected_rows, "Dominant rows 4");

