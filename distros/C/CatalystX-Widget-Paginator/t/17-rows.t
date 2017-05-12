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


is( get('/rows0'), res('rows0'), 'widget' );
is( get('/rows1'), res('rows1'), 'resultset' );
is( get('/rows2'), res('rows2'), 'both' );

