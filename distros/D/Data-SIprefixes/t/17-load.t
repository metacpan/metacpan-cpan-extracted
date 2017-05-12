#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::yocto' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::yocto $Data::SIprefixes::yocto::VERSION, Perl $], $^X" );
