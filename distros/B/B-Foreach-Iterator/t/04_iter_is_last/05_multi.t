#!perl -w

use strict;
use Test::More tests => 3;

use B::Foreach::Iterator;


foreach my $i(10, 11){
	is iter->is_last, q{};
	is iter->is_last, q{};

	is $i, 10;

	last;
}
