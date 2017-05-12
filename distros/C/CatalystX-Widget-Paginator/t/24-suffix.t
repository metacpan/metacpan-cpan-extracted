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


is( get('/suffix0'), res('suffix0'), 'custom' );
is( get('/suffix1'), res('suffix1'), 'none' );
is( get('/suffix2'), res('suffix2'), 'coderef' );

