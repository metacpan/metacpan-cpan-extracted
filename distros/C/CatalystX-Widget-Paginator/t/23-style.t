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


is( get('/style0'), res('style0'), 'custom' );
is( get('/style1'), res('style1'), 'prefix' );

