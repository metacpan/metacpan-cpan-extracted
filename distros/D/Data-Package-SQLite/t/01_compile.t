#!/usr/bin/perl -w

# Load testing for Data::Package::SQLite

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			);
	}
}

use Test::More tests => 7;

# Add the t/lib in both harness and non-harness cases
use lib catdir('t', 'lib');

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok('DBI');
use_ok('DBD::SQLite');
use_ok('Data::Package::SQLite');

# Do the test packages load
use_ok('My::DataPackage1');
use_ok('My::DataPackage2');
use_ok('My::DataPackage3');

exit(0);
