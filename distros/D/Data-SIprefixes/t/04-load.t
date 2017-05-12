#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::deci' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::deci $Data::SIprefixes::deci::VERSION, Perl $], $^X" );
