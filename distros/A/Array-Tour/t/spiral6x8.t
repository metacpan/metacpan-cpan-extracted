# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl spiral6x8.t'.

use Test::Simple tests => 32;

use Array::Tour::Spiral;

use strict;
use warnings;

require "t/helper.pl";

my @dimensions = (6, 8);

my @ok_strings = (
	'lOPQRSkN89ATjM70BUiL61CVhK52DWgJ43EXfIHGFYedcbaZ', # I=0, C=0, B=0, R=0
	'ghijklfKLMNOeJ678PdI509QcH41ARbG32BSaFEDCTZYXWVU', # I=0, C=0, B=0, R=1
	'UVWXYZTCDEFaSB23GbRA14HcQ905IdP876JeONMLKflkjihg', # I=0, C=0, B=1, R=0
	'ZabcdeYFGHIfXE34JgWD25KhVC16LiUB07MjTA98NkSRQPOl', # I=0, C=0, B=1, R=1
	'SRQPOlTA98NkUB07MjVC16LiWD25KhXE34JgYFGHIfZabcde', # I=0, C=1, B=0, R=0
	'lkjihgONMLKfP876JeQ905IdRA14HcSB23GbTCDEFaUVWXYZ', # I=0, C=1, B=0, R=1
	'ZYXWVUaFEDCTbG32BScH41ARdI509QeJ678PfKLMNOghijkl', # I=0, C=1, B=1, R=0
	'edcbaZfIHGFYgJ43EXhK52DWiL61CVjM70BUkN89ATlOPQRS', # I=0, C=1, B=1, R=1
	'012345NOPQR6MdefS7LclgT8KbkhU9JajiVAIZYXWBHGFEDC', # I=1, C=0, B=0, R=0
	'JKLMN0IbcdO1HaleP2GZkfQ3FYjgR4EXihS5DWVUT6CBA987', # I=1, C=0, B=0, R=1
	'789ABC6TUVWD5ShiXE4RgjYF3QfkZG2PelaH1OdcbI0NMLKJ', # I=1, C=0, B=1, R=0
	'CDEFGHBWXYZIAVijaJ9UhkbK8TglcL7SfedM6RQPON543210', # I=1, C=0, B=1, R=1
	'0NMLKJ1OdcbI2PelaH3QfkZG4RgjYF5ShiXE6TUVWD789ABC', # I=1, C=1, B=0, R=0
	'5432106RQPON7SfedM8TglcL9UhkbKAVijaJBWXYZICDEFGH', # I=1, C=1, B=0, R=1
	'HGFEDCIZYXWBJajiVAKbkhU9LclgT8MdefS7NOPQR6012345', # I=1, C=1, B=1, R=0
	'CBA987DWVUT6EXihS5FYjgR4GZkfQ3HaleP2IbcdO1JKLMN0', # I=1, C=1, B=1, R=1
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

