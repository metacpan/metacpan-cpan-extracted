#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::module::version' ) || print "Bail out!\n";
}

diag( "Testing App::module::version $App::module::version::VERSION, Perl $], $^X" );
