#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::peta' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::peta $Data::SIprefixes::peta::VERSION, Perl $], $^X" );
