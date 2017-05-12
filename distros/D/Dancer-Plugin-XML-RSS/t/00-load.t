#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::XML::RSS' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::XML::RSS $Dancer::Plugin::XML::RSS::VERSION, Perl $], $^X" );
