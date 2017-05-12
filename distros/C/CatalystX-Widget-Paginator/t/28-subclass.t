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


is( get('/subclass0'), res('subclass0'), 'default' );
is( get('/subclass1?page=333'), res('subclass1'), 'overrides' );

