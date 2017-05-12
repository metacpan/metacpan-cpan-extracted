#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::View::Template::PHP' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::View::Template::PHP $Catalyst::View::Template::PHP::VERSION, Perl $], $^X" );
