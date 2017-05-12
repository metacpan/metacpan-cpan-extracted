#!/usr/bin/perl

# Formal testing for CSS::Tiny

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;

my $new_called = 0;

# This won't work if a testing module uses Clone
SKIP: {
	skip( "Clone unexpectedly already in use", 13 ) if $INC{'Clone.pm'};

	# Create the broken fake Clone
	$INC{'Clone.pm'} = "FAKED";
	$Clone::VERSION = '10';
	*Clone::import = sub {
		die "Clone is busted";
	};

	# Get rid of some spurious warnings
	*main::foo = *Clone::import;

	# Loads ok when Clone busted?
	use_ok('CSS::Tiny');

	# Replace the new sub with one that signals it was called
	sub mynew {
		$new_called = 1;
		return bless {}, shift;
	}
	*CSS::Tiny::new = *mynew;
	*main::foo = *CSS::Tiny::new;

	# Retry some tests to make sure the fake new works the same
	# Test trivial creation
	my $Trivial = CSS::Tiny->new();
	isa_ok( $Trivial, 'CSS::Tiny' );
	ok( scalar keys %$Trivial == 0, '->new returns an empty object' );

	# Try to read in a config
	my $Config = CSS::Tiny->read( 'test.css' );
	isa_ok( $Config, 'CSS::Tiny' );

	# Repeat the clone tests from 02_main.t
	$new_called = 0;
	my $copy = $Config->clone;
	isa_ok( $copy, 'CSS::Tiny' );
	is_deeply( $copy, $Config, '->clone works as expected' );
	is( $new_called, 1, 'The inline ->clone was used as expected' );
}
