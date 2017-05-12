#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::nano' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::nano $Data::SIprefixes::nano::VERSION, Perl $], $^X" );
