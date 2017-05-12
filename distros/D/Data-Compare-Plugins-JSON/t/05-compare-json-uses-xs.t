#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


BEGIN {
	$ENV{PERL_JSON_BACKEND} = 'JSON::XS';

	plan skip_all => 'JSON::XS required for this test'
		unless eval('use JSON::XS (); 1');
	plan skip_all => 'JSON && JSON::XS (with version limitation) required for this test'
		unless eval('require JSON; 1');
}

use Data::Compare;


ok (JSON->backend eq 'JSON::XS');
for (
	[JSON::false, JSON::false, 1],
	[JSON::false, JSON::true,  0],
	[JSON::false, 0,           1],
	[JSON::false, 1,           0],
	[JSON::true,  JSON::false, 0],
	[JSON::true,  JSON::true,  1],
	[JSON::true,  0,           0],
	[JSON::true,  1,           1],
) {
	ok Compare($_->[0], $_->[1]) == $_->[2];
}


done_testing;
