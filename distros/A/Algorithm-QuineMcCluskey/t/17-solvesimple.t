#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Testing code starts here
#

use Test::More tests => 1;

my $width = 7;
my $divisor = 17;
my $upper = int(((1 << $width) - 1)/$divisor);
my(@minterms) = map {$_ * $divisor} (1 .. $upper);

my(@vars) = qw(a6 a5 a4 a3 a2 a1 a0);

my $q = Algorithm::QuineMcCluskey->new(
	title	=> "$width-bit number divisible by $divisor test",
	width => $width,
	minterms => [ @minterms ],
	vars => [ @vars ],
);

my @expected = (
	q/(a6a5a4a3'a2a1a0) + (a6a5a4'a3'a2a1a0') + (a6a5'a4a3'a2a1'a0) + (a6a5'a4'a3'a2a1'a0') + (a6'a5a4a3'a2'a1a0) + (a6'a5a4'a3'a2'a1a0') + (a6'a5'a4a3'a2'a1'a0)/
);

my $eqn = $q->solve;
ok(scalar (grep($eqn eq $_, @expected)) == 1, $q->title);

