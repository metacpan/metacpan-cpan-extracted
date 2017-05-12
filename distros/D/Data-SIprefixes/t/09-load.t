#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::kilo' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::kilo $Data::SIprefixes::kilo::VERSION, Perl $], $^X" );
