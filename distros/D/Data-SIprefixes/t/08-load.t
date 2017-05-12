#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::hecto' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::hecto $Data::SIprefixes::hecto::VERSION, Perl $], $^X" );
