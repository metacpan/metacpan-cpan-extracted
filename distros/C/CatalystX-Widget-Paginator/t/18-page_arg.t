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
use Test::More tests => 4;


is( get('/page_arg0?p=3'), res('page_arg0'), 'param' );
is( get('/page_arg1?p=3'), res('page_arg1'), 'param / argument' );
is( get('/page_arg2?p=3'), res('page_arg2'), 'param / resultset' );
is( get('/page_arg3?page=3'), res('page_arg3'), 'custom param' );

