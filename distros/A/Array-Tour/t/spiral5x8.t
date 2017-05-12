# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl spiral5x8.t'.

use Test::Simple tests => 32;

use Array::Tour::Spiral;

use strict;
use warnings;

require "t/helper.pl";

my @dimensions = (5, 8);

my @ok_strings = (
	'STUVWRABCXQ90DYP81EZO72FaN63GbM54HcLKJId', # I=0, C=0, B=0, R=0
	'OPQRSN89ATM70BUL61CVK52DWJ43EXIHGFYdcbaZ', # I=0, C=0, B=0, R=1
	'ZabcdYFGHIXE34JWD25KVC16LUB07MTA98NSRQPO', # I=0, C=0, B=1, R=0
	'dIJKLcH45MbG36NaF27OZE18PYD09QXCBARWVUTS', # I=0, C=0, B=1, R=1
	'WVUTSXCBARYD09QZE18PaF27ObG36NcH45MdIJKL', # I=0, C=1, B=0, R=0
	'SRQPOTA98NUB07MVC16LWD25KXE34JYFGHIZabcd', # I=0, C=1, B=0, R=1
	'dcbaZIHGFYJ43EXK52DWL61CVM70BUN89ATOPQRS', # I=0, C=1, B=1, R=0
	'LKJIdM54HcN63GbO72FaP81EZQ90DYRABCXSTUVW', # I=0, C=1, B=1, R=1
	'01234LMNO5KZaP6JYbQ7IXcR8HWdS9GVUTAFEDCB', # I=1, C=0, B=0, R=0
	'IJKL0HYZM1GXaN2FWbO3EVcP4DUdQ5CTSR6BA987', # I=1, C=0, B=0, R=1
	'789AB6RSTC5QdUD4PcVE3ObWF2NaXG1MZYH0LKJI', # I=1, C=0, B=1, R=0
	'BCDEFATUVG9SdWH8RcXI7QbYJ6PaZK5ONML43210', # I=1, C=0, B=1, R=1
	'0LKJI1MZYH2NaXG3ObWF4PcVE5QdUD6RSTC789AB', # I=1, C=1, B=0, R=0
	'432105ONML6PaZK7QbYJ8RcXI9SdWHATUVGBCDEF', # I=1, C=1, B=0, R=1
	'FEDCBGVUTAHWdS9IXcR8JYbQ7KZaP6LMNO501234', # I=1, C=1, B=1, R=0
	'BA987CTSR6DUdQ5EVcP4FWbO3GXaN2HYZM1IJKL0', # I=1, C=1, B=1, R=1
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

