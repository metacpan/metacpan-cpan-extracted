#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 14;

use Convert::Base81 qw(:pack :unpack);

my $b3chars = "01-";

#
# Pairs are [base 3, base 81].
#
my @tests3 = (
	[q(1100), q(a)],
	[q(1101), q(b)],
	[q(11000000), q(a0)],
	[q(11000001), q(a1)],
	[q(10--11111110), q(Zed)],
	[q(0-1101-10000--11010-1-0--00-1111), q(MG0_Blue)],
	[q(0--1-00-1---1110-00-0010-0---0--), q(Purdu3!!)],
);

my $tno = 1;

#
# Base 3 character set string to base81 and back.
#
for my $pair (@tests3)
{
	my($k, $v) = @$pair;
	my $l = length($k);

	my $b81str = b3_pack81($b3chars, $k);
	ok($b81str eq $v, "${tno}a: Base81 string should be '$v', but packed into '$b81str'");

	my $b3str = b3_unpack81($b3chars, $v);
	#diag("$tno: Return length of '$b3str' is ". length($b3str) . ", should be $l");
	#chop $b3str if ($l != length($b3str));
	ok($b3str eq $k, "${tno}b: Base3 string should be '$k', but unpacked into '$b3str'");
	$tno++;
}

