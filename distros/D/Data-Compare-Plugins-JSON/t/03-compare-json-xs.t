#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


BEGIN {
	plan skip_all => 'JSON::XS required for this test'
		unless eval('use JSON::XS (); 1');
}

use Data::Compare;


diag "JSON::XS $JSON::XS::VERSION";

for (
	[JSON::XS::false, JSON::XS::false, 1],
	[JSON::XS::false, JSON::XS::true,  0],
	[JSON::XS::false, 0,               1],
	[JSON::XS::false, 1,               0],
	[JSON::XS::true,  JSON::XS::false, 0],
	[JSON::XS::true,  JSON::XS::true,  1],
	[JSON::XS::true,  0,               0],
	[JSON::XS::true,  1,               1],
) {
	ok Compare($_->[0], $_->[1]) == $_->[2];
}


done_testing;
