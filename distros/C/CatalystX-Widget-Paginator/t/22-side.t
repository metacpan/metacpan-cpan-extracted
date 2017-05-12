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


is( get('/side0'), res('side0'), 'custom' );
is( get('/side1'), res('side1'), 'none' );

