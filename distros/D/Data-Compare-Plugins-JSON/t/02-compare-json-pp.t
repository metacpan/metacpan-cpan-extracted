#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


BEGIN {
	plan skip_all => 'JSON::PP required for this test'
		unless eval('use JSON::PP (); 1');
}

use Data::Compare;

diag "JSON::PP $JSON::PP::VERSION";

for (
	[JSON::PP::false, JSON::PP::false, 1],
	[JSON::PP::false, JSON::PP::true,  0],
	[JSON::PP::false, 0,               1],
	[JSON::PP::false, 1,               0],
	[JSON::PP::true,  JSON::PP::false, 0],
	[JSON::PP::true,  JSON::PP::true,  1],
	[JSON::PP::true,  0,               0],
	[JSON::PP::true,  1,               1],
) {
	ok Compare($_->[0], $_->[1]) == $_->[2];
}


done_testing;
