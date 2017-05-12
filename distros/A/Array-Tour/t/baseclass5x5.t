# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl baseclass5x5.t'.

use Test::Simple tests => 1;

use Array::Tour;

use strict;
use warnings;

require "t/helper.pl";

my $width = 5;

my @ok_strings = (
	'0123456789ABCDEFGHIJKLMNO',
);

for my $j (0 .. $#ok_strings)
{
	my $reverse = $j & 1;

	my $dflt_tour = Array::Tour->new(
		dimensions => $width,
		reverse => $reverse);

	my @grid = makegrid($dflt_tour);
	my $dflt_tourstr = join("", @grid);
	ok(($dflt_tourstr eq $ok_strings[$j]), "test$j");
}
exit(0);

