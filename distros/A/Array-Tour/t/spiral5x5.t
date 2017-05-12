# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl spiral5x5.t'.

use Test::Simple tests => 32;

use Array::Tour::Spiral;

use strict;
use warnings;

require "t/helper.pl";

my $width = 5;

my @ok_strings = (
	'KLMNOJ6789I501AH432BGFEDC', # I=0, C=0, B=0, R=0
	'GHIJKF456LE307MD218NCBA9O', # I=0, C=0, B=0, R=1
	'O9ABCN812DM703EL654FKJIHG', # I=0, C=0, B=1, R=0
	'CDEFGB234HA105I9876JONMLK', # I=0, C=0, B=1, R=1
	'KJIHGL654FM703EN812DO9ABC', # I=0, C=1, B=0, R=0
	'ONMLK9876JA105IB234HCDEFG', # I=0, C=1, B=0, R=1
	'GFEDCH432BI501AJ6789KLMNO', # I=0, C=1, B=1, R=0
	'CBA9OD218NE307MF456LGHIJK', # I=0, C=1, B=1, R=1
	'01234FGHI5ENOJ6DMLK7CBA98', # I=1, C=0, B=0, R=0
	'CDEF0BMNG1ALOH29KJI387654', # I=1, C=0, B=0, R=1
	'456783IJK92HOLA1GNMB0FEDC', # I=1, C=0, B=1, R=0
	'89ABC7KLMD6JONE5IHGF43210', # I=1, C=0, B=1, R=1
	'0FEDC1GNMB2HOLA3IJK945678', # I=1, C=1, B=0, R=0
	'432105IHGF6JONE7KLMD89ABC', # I=1, C=1, B=0, R=1
	'CBA98DMLK7ENOJ6FGHI501234', # I=1, C=1, B=1, R=0
	'876549KJI3ALOH2BMNG1CDEF0', # I=1, C=1, B=1, R=1
);


for my $j (0..15)
{
	my $corner_right = $j & 1;
	my $corner_bottom = ($j & 2) >> 1;
	my $counterclock = ($j & 4) >> 2;
	my $inward = ($j & 8) >> 3;

	my $idstr = "I:$inward C:$counterclock B:$corner_bottom R:$corner_right";

	my $spiral = Array::Tour::Spiral->new(
		dimensions => $width,
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

