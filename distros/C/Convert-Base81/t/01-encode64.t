#!perl
use warnings;
use strict;

use Test::More tests => 10;

use Convert::Base81 qw(base81_encode base81_decode rwsize);

my @codings = (
	[qq(\x01\x02\x03\x04\x05\x06\x07) x 8, q(0CWaodvuz) x 8],
	[q(01234560123456), q/7P{No6C_(7P{No6C_(/],
	[q(789abcd789abcd), q/8VX~burkS8VX~burkS/],
	[q(0123456789abcd), q/7P{No6C_(8VX~burkS/],
	[q(0123456789abcdef), q/7P{No6C_(8VX~burkSFWmx75+%*/],
);

#
# Do the 7, 9 encode/decode version.
#
my $tno = 1;

rwsize('I64');

for my $pair (@codings)
{
	my ($text, $encoded) = @$pair;
	my $l = length($text);

	my $test_encode = base81_encode($text);
	ok($test_encode eq $encoded, "${tno}a: '$text' encoded into '$test_encode', not '$encoded'");

	my $test_decode = base81_decode($encoded);
	my $padding = length($test_decode) - $l;
	#diag("Difference in lengths between original and decoded is ", $padding);
	chop $test_decode while ($padding-- > 0);
	ok($test_decode eq $text, "${tno}b: '$encoded' decoded into '$test_decode', not '$text'");

	$tno += 1;
}

