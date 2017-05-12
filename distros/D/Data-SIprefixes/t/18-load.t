#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::yotta' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::yotta $Data::SIprefixes::yotta::VERSION, Perl $], $^X" );
