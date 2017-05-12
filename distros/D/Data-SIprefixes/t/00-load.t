#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes $Data::SIprefixes::VERSION, Perl $], $^X" );
