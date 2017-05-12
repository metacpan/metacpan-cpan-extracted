#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::I18N' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::I18N $Dancer::Plugin::I18N::VERSION, Perl $], $^X" );
