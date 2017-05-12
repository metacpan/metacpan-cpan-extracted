#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::zetta' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::zetta $Data::SIprefixes::zetta::VERSION, Perl $], $^X" );
