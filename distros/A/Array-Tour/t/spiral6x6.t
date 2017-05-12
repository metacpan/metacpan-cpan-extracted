# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl spiral6x6.t'.

use Test::Simple tests => 32;

use Array::Tour::Spiral;

use strict;
use warnings;

require "t/helper.pl";

my @dimensions = (6, 6);

my @ok_strings = (
	'KLMNOPJ6789QI501ARH432BSGFEDCTZYXWVU', # I=0, C=0, B=0, R=0
	'ZGHIJKYF456LXE307MWD218NVCBA9OUTSRQP', # I=0, C=0, B=0, R=1
	'PQRSTUO9ABCVN812DWM703EXL654FYKJIHGZ', # I=0, C=0, B=1, R=0
	'UVWXYZTCDEFGSB234HRA105IQ9876JPONMLK', # I=0, C=0, B=1, R=1
	'KJIHGZL654FYM703EXN812DWO9ABCVPQRSTU', # I=0, C=1, B=0, R=0
	'PONMLKQ9876JRA105ISB234HTCDEFGUVWXYZ', # I=0, C=1, B=0, R=1
	'ZYXWVUGFEDCTH432BSI501ARJ6789QKLMNOP', # I=0, C=1, B=1, R=0
	'UTSRQPVCBA9OWD218NXE307MYF456LZGHIJK', # I=0, C=1, B=1, R=1
	'012345JKLMN6IVWXO7HUZYP8GTSRQ9FEDCBA', # I=1, C=0, B=0, R=0
	'FGHIJ0ETUVK1DSZWL2CRYXM3BQPON4A98765', # I=1, C=0, B=0, R=1
	'56789A4NOPQB3MXYRC2LWZSD1KVUTE0JIHGF', # I=1, C=0, B=1, R=0
	'ABCDEF9QRSTG8PYZUH7OXWVI6NMLKJ543210', # I=1, C=0, B=1, R=1
	'0JIHGF1KVUTE2LWZSD3MXYRC4NOPQB56789A', # I=1, C=1, B=0, R=0
	'5432106NMLKJ7OXWVI8PYZUH9QRSTGABCDEF', # I=1, C=1, B=0, R=1
	'FEDCBAGTSRQ9HUZYP8IVWXO7JKLMN6012345', # I=1, C=1, B=1, R=0
	'A98765BQPON4CRYXM3DSZWL2ETUVK1FGHIJ0', # I=1, C=1, B=1, R=1
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

