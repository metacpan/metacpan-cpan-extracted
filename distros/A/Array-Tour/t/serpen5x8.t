# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl serpen5x5.t'.

use Test::Simple tests => 8;

use Array::Tour::Serpentine;

use strict;
use warnings;

require "t/helper.pl";

my @dimensions = (5, 8);

my @ok_strings = (
	'0123498765ABCDEJIHGFKLMNOTSRQPUVWXYdcbaZ', # V=0, B=0, R=0
	'4321056789EDCBAFGHIJONMLKPQRSTYXWVUZabcd', # V=0, B=0, R=1
	'dcbaZUVWXYTSRQPKLMNOJIHGFABCDE9876501234', # V=0, B=1, R=0
	'ZabcdYXWVUPQRSTONMLKFGHIJEDCBA5678943210', # V=0, B=1, R=1
	'0FGVW1EHUX2DITY3CJSZ4BKRa5ALQb69MPc78NOd', # V=1, B=0, R=0
	'WVGF0XUHE1YTID2ZSJC3aRKB4bQLA5cPM96dON87', # V=1, B=0, R=1
	'78NOd69MPc5ALQb4BKRa3CJSZ2DITY1EHUX0FGVW', # V=1, B=1, R=0
	'dON87cPM96bQLA5aRKB4ZSJC3YTID2XUHE1WVGF0', # V=1, B=1, R=1
);


for my $j (0..7)
{
	my $corner_right = $j & 1;
	my $corner_bottom = ($j & 2) >> 1;
	my $vertical = ($j & 4) >> 2;

	my $idstr = "V:$vertical B:$corner_bottom R:$corner_right";

	my $serpen = Array::Tour::Serpentine->new(
		dimensions => \@dimensions,
		corner_right => $corner_right,
		corner_bottom => $corner_bottom,
		vertical => $vertical);

	my @grid = makegrid($serpen);
	my $serpenstr = join("", @grid);

#	print "'", $serpenstr, "'\n";
	ok(($serpenstr eq $ok_strings[$j]), $idstr);
}
exit(0);

