# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl serpen5x5.t'.

use Test::Simple tests => 8;

use Array::Tour::Serpentine;

use strict;
use warnings;

require "t/helper.pl";

my $width = 5;

my @ok_strings = (
	'0123498765ABCDEJIHGFKLMNO', # V=0, B=0, R=0
	'4321056789EDCBAFGHIJONMLK', # V=0, B=0, R=1
	'KLMNOJIHGFABCDE9876501234', # V=0, B=1, R=0
	'ONMLKFGHIJEDCBA5678943210', # V=0, B=1, R=1
	'09AJK18BIL27CHM36DGN45EFO', # V=1, B=0, R=0
	'KJA90LIB81MHC72NGD63OFE54', # V=1, B=0, R=1
	'45EFO36DGN27CHM18BIL09AJK', # V=1, B=1, R=0
	'OFE54NGD63MHC72LIB81KJA90', # V=1, B=1, R=1
);


for my $j (0..7)
{
	my $corner_right = $j & 1;
	my $corner_bottom = ($j & 2) >> 1;
	my $vertical = ($j & 4) >> 2;

	my $idstr = "V:$vertical B:$corner_bottom R:$corner_right";

	my $serpen = Array::Tour::Serpentine->new(
		dimensions => $width,
		corner_right => $corner_right,
		corner_bottom => $corner_bottom,
		vertical => $vertical);

	my @grid = makegrid($serpen);
	my $serpenstr = join("", @grid);

#	print "'", $serpenstr, "'\n";
	ok(($serpenstr eq $ok_strings[$j]), $idstr);
}
exit(0);

