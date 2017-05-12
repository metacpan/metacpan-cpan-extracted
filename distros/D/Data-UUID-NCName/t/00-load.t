#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::UUID::NCName' ) || print "Bail out!\n";
}

diag( "Testing Data::UUID::NCName $Data::UUID::NCName::VERSION, Perl $], $^X" );
