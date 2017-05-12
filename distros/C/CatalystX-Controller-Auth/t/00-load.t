#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CatalystX::Controller::Auth' ) || print "Bail out!\n";
}

diag( "Testing CatalystX::Controller::Auth $CatalystX::Controller::Auth::VERSION, Perl $], $^X" );
