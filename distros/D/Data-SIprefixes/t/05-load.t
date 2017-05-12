#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::exa' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::exa $Data::SIprefixes::exa::VERSION, Perl $], $^X" );
