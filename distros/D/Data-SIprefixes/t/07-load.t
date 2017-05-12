#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::giga' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::giga $Data::SIprefixes::giga::VERSION, Perl $], $^X" );
