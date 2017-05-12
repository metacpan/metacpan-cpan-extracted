#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
	use File::Spec;
	use FindBin '$Bin';
	use lib File::Spec->catdir($Bin,'lib');
}

use TestApp::boot;
use Catalyst::Test 'TestApp';
use Test::More tests => 3;


is( get('/'), 'ok', 'index' );
is( get('/nonexistent'), 'not found', 'nonexistent' );
is( get('/user'), 'user-1', 'user' );

