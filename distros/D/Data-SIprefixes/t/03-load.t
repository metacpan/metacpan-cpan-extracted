#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::deca' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::deca $Data::SIprefixes::deca::VERSION, Perl $], $^X" );
