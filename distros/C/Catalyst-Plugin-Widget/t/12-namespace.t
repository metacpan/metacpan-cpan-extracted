#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin '$Bin';
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';
use Test::More tests => 4;


SKIP: {
	eval { require Catalyst::View::TT };

	skip 'Catalyst::View::TT not instaled', 1
		if $@;

	like( get( '/ns1' ), qr'ok' );
}

like( get( '/ns' .$_ ), qr'ok' )
	for 2 .. 4;

