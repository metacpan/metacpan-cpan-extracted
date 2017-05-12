#!/usr/bin/perl
use 5.008009;
use strict;
use warnings;

use Convert::Color;
use Test::More tests => 16;

my @tests = (
	[qw/hsluv H S L hsl/],
	[qw/lch   L C h lch/],
	[qw/luv   L u v luv/],
	[qw/xyz   X Y Z xyz/],
);

for (@tests) {
	my ($name, $x, $y, $z, $xyz) =  @$_;
	my $col = Convert::Color->new("$name:1,2,3");
	is $col->$x, 1, "\$$name->$x";
	is $col->$y, 2, "\$$name->$y";
	is $col->$z, 3, "\$$name->$z";
	is_deeply [$col->$xyz], [1, 2, 3], "\$$name->$xyz"
}
