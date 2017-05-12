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
use Test::More tests => 2;


is( get('/edges0'), res('edges0'), 'custom' );
is( get('/edges1'), res('edges1'), 'none' );

