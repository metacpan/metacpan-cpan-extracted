#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::wrapspeak' ) || print "Bail out!\n";
}

diag( "Testing App::wrapspeak $App::wrapspeak::VERSION, Perl $], $^X" );
