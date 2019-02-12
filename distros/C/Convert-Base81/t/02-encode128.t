#!perl
use warnings;
use strict;

use Test::More tests => 10;

use Convert::Base81 qw(base81_encode base81_decode rwsize);

my @codings = (
	[qq(\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f) x 8, q/0I(3^6A5qGtiJ$yGx70/ x 8],
	[q(0123456789abcde), q/B8tgH^#*2vB%^_bQ)f9/],
	[q(edcba9876543210), q/NT+rQtXqO2NG1iyd!_X/],
	[q(edcba98765432100123456789abcde), q/NT+rQtXqO2NG1iyd!_XB8tgH^#*2vB%^_bQ)f9/],
	[q(In my mind's reception room/Which is what, and who is whom?/I notice when the candle's lighted/Half the guests are uninvited,/And oddest fancies, merriest jests,/Come from these unbidden guests. -- 'The Reward', by Ogden Nash),
	q/G@*jPT1e3bGEQ@|PqUOM?mhb~y{%2#8dt-;4?EONbgIf@DPJ4EP)~U5u9N6JNGU^wYM%TP$T$=!)G+EoR~VKXv7O{iAZ*{HO4@fuKU6j~r9jz}pTRPO62vhfoGqMrL=X8)l6^R4pk$;trlc6lQD;GV$yOOu-?!G)P7Fs5y}LFvvQz^hS)^AX#i-_!D2G)ZONnmPjGB$Mux?)$5WTrNO?4-|?MvNszret;;P%MtHwVDq#0r1Aw9Ah|pWAXU}hnLS9%q_nWd=33(AD#jCdUFQ~e3D*CO;RP/],
);

#
# Performing the default read 15/write 19 encode/decode version.
#
my $tno = 1;

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

