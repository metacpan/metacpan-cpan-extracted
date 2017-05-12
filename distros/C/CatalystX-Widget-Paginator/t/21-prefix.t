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


is( get('/prefix0'), res('prefix0'), 'custom' );
is( get('/prefix1'), res('prefix1'), 'none' );
is( get('/prefix2'), res('prefix2'), 'coderef' );

