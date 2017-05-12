#!/usr/bin/perl

# Load test the Archive::Builder module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;

# Check their perl version
ok( $] >= 5.005, 'Your perl is new enough' );

# Load all of the classes
use_ok( 'Archive::Builder'             );
use_ok( 'Archive::Builder::Section'    );
use_ok( 'Archive::Builder::File'       );
use_ok( 'Archive::Builder::Generators' );
use_ok( 'Archive::Builder::Archive'    );
