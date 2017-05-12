#!/usr/bin/perl

# Compile testing for Business::AU::ABN

use 5.005;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

use_ok( 'Business::AU::ABN' );
