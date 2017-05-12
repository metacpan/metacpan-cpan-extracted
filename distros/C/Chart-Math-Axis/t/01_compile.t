#!/usr/bin/perl 

# Compile testing for Chart::Math::Axis

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

use_ok('Chart::Math::Axis');
