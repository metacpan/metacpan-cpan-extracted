#!perl -w

use strict;
use Test::More tests => 15;

use B::Foreach::Iterator;


foreach my $i(10){
	is iter->next, undef;
	is iter->next, undef;

	is $i, 10;
}

foreach my $i(reverse 10){
	is iter->next, undef;
	is iter->next, undef;

	is $i, 10;
}

foreach my $i('a'){
	is iter->next, undef;
	is iter->next, undef;

	is $i, 'a';
}

foreach my $i(reverse 'a'){
	is iter->next, undef;
	is iter->next, undef;

	is $i, 'a';
}

foreach my $i(10 .. 11){
	is iter->next, 11;
	is iter->next, undef;

	is $i, 10;
}
