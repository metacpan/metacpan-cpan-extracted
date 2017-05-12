#!perl

use strict;
use warnings;

use Chess::FIDE;
use Test::More tests => 6;

my $fide = Chess::FIDE->new(
	-file => 't/data/test-list.txt'
);
my @res = $fide->fideSearch("id == 4158814");
is(scalar(@res), 1, "Exact match found");
@res = $fide->fideSearch("surname eq 'Andreoli'");
is(scalar(@res), 4, "Four exact matches found");

for (@res) {
	is($_->{surname}, 'Andreoli', 'indeed search matches');
}
