#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Taskflow' ) || print "Bail out!\n";
}

diag( "Testing App::Taskflow $App::Taskflow::VERSION, Perl $], $^X" );
