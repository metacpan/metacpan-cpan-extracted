#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::zepto' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::zepto $Data::SIprefixes::zepto::VERSION, Perl $], $^X" );
