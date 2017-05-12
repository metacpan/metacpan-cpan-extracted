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
use Test::More tests => 5;


is( get('/invalid0'), res ('invalid0'), 'default' );
is( get('/invalid1'), res ('invalid1'), 'last' );
is( get('/invalid2'), res ('invalid2'), 'raise' );
is( get('/invalid3'), res ('invalid3'), 'coderef' );
is( get('/invalid4'), res ('invalid4'), 'first' );

