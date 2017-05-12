# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl spiral8x5.t'.

use Test::Simple tests => 32;

use Array::Tour::Spiral;

use strict;
use warnings;

require "t/helper.pl";

my @dimensions = (8, 5);

my @ok_strings = (
	'WXYZabcdVCDEFGHIUB01234JTA98765KSRQPONML', # I=0, C=0, B=0, R=0
	'dIJKLMNOcH45678PbG32109QaFEDCBARZYXWVUTS', # I=0, C=0, B=0, R=1
	'STUVWXYZRABCDEFaQ90123GbP87654HcONMLKJId', # I=0, C=0, B=1, R=0
	'LMNOPQRSK56789ATJ43210BUIHGFEDCVdcbaZYXW', # I=0, C=0, B=1, R=1
	'SRQPONMLTA98765KUB01234JVCDEFGHIWXYZabcd', # I=0, C=1, B=0, R=0
	'ZYXWVUTSaFEDCBARbG32109QcH45678PdIJKLMNO', # I=0, C=1, B=0, R=1
	'ONMLKJIdP87654HcQ90123GbRABCDEFaSTUVWXYZ', # I=0, C=1, B=1, R=0
	'dcbaZYXWIHGFEDCVJ43210BUK56789ATLMNOPQRS', # I=0, C=1, B=1, R=1
	'01234567LMNOPQR8KZabcdS9JYXWVUTAIHGFEDCB', # I=1, C=0, B=0, R=0
	'FGHIJKL0EVWXYZM1DUdcbaN2CTSRQPO3BA987654', # I=1, C=0, B=0, R=1
	'456789AB3OPQRSTC2NabcdUD1MZYXWVE0LKJIHGF', # I=1, C=0, B=1, R=0
	'BCDEFGHIATUVWXYJ9SdcbaZK8RQPONML76543210', # I=1, C=0, B=1, R=1
	'0LKJIHGF1MZYXWVE2NabcdUD3OPQRSTC456789AB', # I=1, C=1, B=0, R=0
	'765432108RQPONML9SdcbaZKATUVWXYJBCDEFGHI', # I=1, C=1, B=0, R=1
	'IHGFEDCBJYXWVUTAKZabcdS9LMNOPQR801234567', # I=1, C=1, B=1, R=0
	'BA987654CTSRQPO3DUdcbaN2EVWXYZM1FGHIJKL0', # I=1, C=1, B=1, R=1
);


for my $j (0..15)
{
	my $corner_right = $j & 1;
	my $corner_bottom = ($j & 2) >> 1;
	my $counterclock = ($j & 4) >> 2;
	my $inward = ($j & 8) >> 3;

	my $idstr = "I:$inward C:$counterclock B:$corner_bottom R:$corner_right";

	my $spiral = Array::Tour::Spiral->new(
		dimensions => \@dimensions,
		corner_right => $corner_right,
		corner_bottom => $corner_bottom,
		counterclock => $counterclock,
		inward => $inward);

	my @grid = makegrid($spiral);
	my $gridstr = join("", @grid);
	ok(($gridstr eq $ok_strings[$j]), "     $idstr");

	my $larips = $spiral->anti_spiral();
	my %ap = $larips->describe();
	my $anti_j = $ap{corner_right} | ($ap{corner_bottom} << 1) |
			($ap{counterclock} << 2) | ($ap{inward} << 3);
	@grid = makegrid($larips);
	$gridstr = join("", @grid);
	ok(($gridstr eq $ok_strings[$anti_j]), "anti $idstr");

#	print "'", $gridstr, "'\n'", $laripsstr, "'\n";
}
exit(0);

