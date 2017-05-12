#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Validate::VIN' ) || print "Bail out!\n";
}

diag( "Testing Data::Validate::VIN $Data::Validate::VIN::VERSION, Perl $], $^X" );
