#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::mega' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::mega $Data::SIprefixes::mega::VERSION, Perl $], $^X" );
