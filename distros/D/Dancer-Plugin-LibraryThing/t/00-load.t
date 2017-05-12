#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::LibraryThing' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::LibraryThing $Dancer::Plugin::LibraryThing::VERSION, Perl $], $^X" );
