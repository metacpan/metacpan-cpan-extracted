#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::BootstrapAlert' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::BootstrapAlert $Catalyst::Plugin::BootstrapAlert::VERSION, Perl $], $^X" );
