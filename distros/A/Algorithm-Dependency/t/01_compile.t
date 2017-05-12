#!/usr/bin/perl

# Basic load and method existance tests for Algorithm::Dependency

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 16;




# Check their perl version
ok( $] > 5.005, 'Perl version is new enough' );

# Load the main modules
use_ok( 'Algorithm::Dependency'               );
use_ok( 'Algorithm::Dependency::Ordered'      );
use_ok( 'Algorithm::Dependency::Weight'       );
use_ok( 'Algorithm::Dependency::Source::File' );
use_ok( 'Algorithm::Dependency::Source::HoA'  );

# Check for version lock
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Ordered::VERSION,
    '$VERSION matches for ::Ordered' );
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Weight::VERSION,
    '$VERSION matches for ::Weight' );
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Source::VERSION,
    '$VERSION matches for ::Source' );
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Source::File::VERSION,
    '$VERSION matches for ::Source::File' );
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Source::HoA::VERSION,
    '$VERSION matches for ::Source::HoA' );

# Do it again to avoid warnings
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Ordered::VERSION,
    '$VERSION matches for ::Ordered' );
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Weight::VERSION,
    '$VERSION matches for ::Weight' );
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Source::VERSION,
    '$VERSION matches for ::Source' );
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Source::File::VERSION,
    '$VERSION matches for ::Source::File' );
is( $Algorithm::Dependency::VERSION,
    $Algorithm::Dependency::Source::HoA::VERSION,
    '$VERSION matches for ::Source::HoA' );
