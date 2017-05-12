#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
	use File::Spec;
	use FindBin '$Bin';
	use lib File::Spec->catdir($Bin,'lib');
}

use TestApp::boot qw( res );
use Catalyst::Test 'TestApp';
use Test::More tests => 3;


is( get('/page0'), res('page0'), 'argument' );
is( get('/page1'), res('page1'), 'resulset' );
is( get('/page2'), res('page2'), 'both' );

