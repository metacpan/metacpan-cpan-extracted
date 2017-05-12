#!/usr/bin/perl

# Load testing for CGI::Capture

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

# Check their perl version
ok( $] >= 5.006, 'Your perl is new enough' );

# Does the module load
use_ok('CGI::Capture');

# Does the script compile
script_compiles_ok('script/cgicapture');
