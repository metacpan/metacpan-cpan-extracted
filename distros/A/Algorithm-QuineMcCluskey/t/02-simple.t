#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;


#
# Testing code starts here
#

use Test::More tests => 2;

my $q = Algorithm::QuineMcCluskey->new(
	title	=> "Simple 4-minterm problem",
	width => 3,
	minterms => [ 0, 3, 5, 7 ],
	dc => "x"
);

my %expected_primes = (
	'000' => [ '000' ],
	'x11' => [ '011', '111' ],
	'1x1' => [ '101', '111' ],
);


my $primes = $q->get_primes;
is_deeply($primes, \%expected_primes, $q->title);


$q = Algorithm::QuineMcCluskey->new(
	title	=> "Simple 6-minterm problem",
	width => 4,
	minterms => [ 3, 5, 7, 8, 9, 10 ],
	dc => "x"
);

%expected_primes = (
	'01x1' => [ '0101', '0111' ],
	'100x' => [ '1000', '1001' ],
	'0x11' => [ '0011', '0111' ],
	'10x0' => [ '1010', '1000' ]
);



$primes = $q->get_primes;
is_deeply($primes, \%expected_primes, $q->title);

