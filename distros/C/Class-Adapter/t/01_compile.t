#!/usr/bin/perl

# Compile testing for Class::Adapter

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;

# Sometimes it's hard to know when different Scalar::Util tools turned up.
# So confirm the existance of blessed
use_ok( 'Scalar::Util' );
ok(
	defined(&Scalar::Util::blessed),
	'blessed exists in Scalar::Util',
);

# Does the module load
use_ok( 'Class::Adapter'          );
use_ok( 'Class::Adapter::Builder' );
use_ok( 'Class::Adapter::Clear'   );
