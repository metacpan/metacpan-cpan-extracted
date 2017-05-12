#!/usr/bin/perl -T

# Full testing for Chart::Math::Axis

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More ();

# Can we do tainting tests?
BEGIN {
	eval {
		require Test::Taint;
	};
	if ( $Test::Taint::VERSION ) {
		Test::More::plan( tests => 5 );
	} else {
		Test::More::plan( skip_all => 'Skipping taint tests (no Taint.pm)' );
		exit(0);
	}
}

use Math::BigInt;
use Math::BigFloat;
use Chart::Math::Axis;





#####################################################################
# Test the reported tainting case

Test::Taint::taint_checking_ok( 'Tainting is enabled' );

my @data = ( 1, 0.5 );
Test::Taint::untainted_ok_deeply(\@data, 'Data not tainted' );

Test::Taint::taint( $data[0] );
Test::Taint::taint( $data[0] );
Test::Taint::taint( @data    );
Test::Taint::tainted_ok_deeply(\@data, 'Data is now tainted' );

my $foo = Chart::Math::Axis->new(@data);
Test::More::isa_ok( $foo, 'Chart::Math::Axis' );
Test::Taint::untainted_ok_deeply( $foo, 'Data is now tainted' );
