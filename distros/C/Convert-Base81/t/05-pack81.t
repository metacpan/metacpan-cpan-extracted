#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 12;

use Convert::Base81 qw(:pack :unpack);

my $b27chars = "0123456789abcdefghijklmnopq";

#
# Pairs are [base 27, base 81].
#
my @tests27 = (
	[q(c0), q(a)],
	[q(7al0pa7kimc), q(MG0_Blue)],
	[q(8f7qd663koo), q(Purdu3!!)],
	[q(9f30h14md1mn), q(St0pAndGo)],
	[q(qqp5hmpfef5qqi), q(~~Wright~~)],
	[q(kfk5jfb2if1qhejn), q(zyxwvutsrqpo)],
);

my $tno = 1;

#
# Base 27 character set string to base81 and back.
#
for my $pair (@tests27)
{
	my($k, $v) = @$pair;
	my $l = length($k);

	my $b81str = b27_pack81($b27chars, $k);
	ok($b81str eq $v, "${tno}a: Base81 string should be '$v', but packed into '$b81str'");

	my $b27str = b27_unpack81($b27chars, $v);
	#diag("$tno: Return length of '$b27str' is ". length($b27str) . ", should be $l");
	#chop $b27str if ($l != length($b27str));
	ok($b27str eq $k, "${tno}b: Base27 string should be '$k', but unpacked into '$b27str'");
	$tno++;
}


