#!/usr/bin/perl

# Compile testing for Class::Autouse

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;

# Check their perl version
ok( $] >= 5.006, "Your perl is new enough" );

# Does the module load
use_ok('Class::Autouse'        );
use_ok('Class::Autouse::Parent');

# Check version locking
is( $Class::Autouse::VERSION, $Class::Autouse::Parent::VERSION,
	'C:A and C:A:Parent versions match' );

# Again to avoid warnings
is( $Class::Autouse::VERSION, $Class::Autouse::Parent::VERSION,
	'C:A and C:A:Parent versions match' );
