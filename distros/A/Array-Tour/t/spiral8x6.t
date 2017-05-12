# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl spiral8x6.t'.

use Test::Simple tests => 32;

use Array::Tour::Spiral;

use strict;
use warnings;

require "t/helper.pl";

my @dimensions = (8, 6);

my @ok_strings = (
	'STUVWXYZRABCDEFaQ90123GbP87654HcONMLKJIdlkjihgfe', # I=0, C=0, B=0, R=0
	'ZabcdefgYFGHIJKhXE3456LiWD2107MjVCBA98NkUTSRQPOl', # I=0, C=0, B=0, R=1
	'lOPQRSTUkN89ABCVjM7012DWiL6543EXhKJIHGFYgfedcbaZ', # I=0, C=0, B=1, R=0
	'efghijkldIJKLMNOcH45678PbG32109QaFEDCBARZYXWVUTS', # I=0, C=0, B=1, R=1
	'lkjihgfeONMLKJIdP87654HcQ90123GbRABCDEFaSTUVWXYZ', # I=0, C=1, B=0, R=0
	'UTSRQPOlVCBA98NkWD2107MjXE3456LiYFGHIJKhZabcdefg', # I=0, C=1, B=0, R=1
	'gfedcbaZhKJIHGFYiL6543EXjM7012DWkN89ABCVlOPQRSTU', # I=0, C=1, B=1, R=0
	'ZYXWVUTSaFEDCBARbG32109QcH45678PdIJKLMNOefghijkl', # I=0, C=1, B=1, R=1
	'01234567NOPQRST8MdefghU9LclkjiVAKbaZYXWBJIHGFEDC', # I=1, C=0, B=0, R=0
	'HIJKLMN0GZabcdO1FYjkleP2EXihgfQ3DWVUTSR4CBA98765', # I=1, C=0, B=0, R=1
	'56789ABC4RSTUVWD3QfghiXE2PelkjYF1OdcbaZG0NMLKJIH', # I=1, C=0, B=1, R=0
	'CDEFGHIJBWXYZabKAVijklcL9UhgfedM8TSRQPON76543210', # I=1, C=0, B=1, R=1
	'0NMLKJIH1OdcbaZG2PelkjYF3QfghiXE4RSTUVWD56789ABC', # I=1, C=1, B=0, R=0
	'765432108TSRQPON9UhgfedMAVijklcLBWXYZabKCDEFGHIJ', # I=1, C=1, B=0, R=1
	'JIHGFEDCKbaZYXWBLclkjiVAMdefghU9NOPQRST801234567', # I=1, C=1, B=1, R=0
	'CBA98765DWVUTSR4EXihgfQ3FYjkleP2GZabcdO1HIJKLMN0', # I=1, C=1, B=1, R=1
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

