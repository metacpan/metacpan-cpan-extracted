#!perl
use warnings;
use strict;

use Test::More tests => 4;

use Convert::Base85 qw(base85_encode base85_decode);

my @codings = (
	["\x10\x20\x30\x40\x50\x60\x70\x80" x 2, '4xlQ-6s&i4q&K``>25ul'],
	["qwertyuiopasdfghjklz", 'X6Z=}*UKUhjzkyJz6q{oV1*z*EDBk017ba52hbNI'],
);

my $tno = 1;

for my $pair (@codings)
{
	my ($text, $encoded) = @$pair;
	my $l = length($text);

	my $test_encode = base85_encode($text);
	ok($test_encode eq $encoded, "${tno}a: '$text' encoded into '$test_encode', not '$encoded'");

	my $test_decode = base85_decode($encoded);
	my $padding = length($test_decode) - $l;
	#diag("Difference in lengths between original and decoded is ", $padding);
	chop $test_decode while ($padding-- > 0);
	ok($test_decode eq $text, "${tno}b: '$encoded' decoded into '$test_decode', not '$text'");

	$tno += 1;
}
