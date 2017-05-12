#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::centi' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::centi $Data::SIprefixes::centi::VERSION, Perl $], $^X" );
