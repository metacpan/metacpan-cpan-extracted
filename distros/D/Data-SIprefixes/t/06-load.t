#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::femto' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::femto $Data::SIprefixes::femto::VERSION, Perl $], $^X" );
