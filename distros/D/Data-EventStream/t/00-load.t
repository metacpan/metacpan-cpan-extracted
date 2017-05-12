#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::EventStream' ) || print "Bail out!\n";
}

diag( "Testing Data::EventStream $Data::EventStream::VERSION, Perl $], $^X" );
