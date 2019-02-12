#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 12;

use Convert::Base81 qw(:pack :unpack);

my $b9chars = "012345678";

#
# Pairs are [base 9, base 81].
#
my @tests9 = (
	[q(40), q(a)],
	[q(41), q(b)],
	[q(4000), q(a0)],
	[q(4001), q(a1)],
	[q(2417008412526244), q(MG0_Blue)],
	[q(2762584362036868), q(Purdu3!!)],
);

my $tno = 1;

#
# Base 9 character set string to base81 and back.
#
for my $pair (@tests9)
{
	my($k, $v) = @$pair;
	my $l = length($v);

	my $b81str = b9_pack81($b9chars, $k);
	ok($b81str eq $v, "${tno}a: Base81 string should be '$v', but packed into '$b81str'");

	my $b9str = b9_unpack81($b9chars, $v);
	#chop $b9str if ($l != length($b9str));
	ok($b9str eq $k, "${tno}b: Base9 string should be '$k', but unpacked into '$b9str'");
	$tno++;
}

