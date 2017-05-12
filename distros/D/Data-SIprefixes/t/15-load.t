#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::pico' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::pico $Data::SIprefixes::pico::VERSION, Perl $], $^X" );
