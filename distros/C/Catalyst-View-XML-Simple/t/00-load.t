#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::View::XML::Simple' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::View::XML::Simple $Catalyst::View::XML::Simple::VERSION, Perl $], $^X" );
