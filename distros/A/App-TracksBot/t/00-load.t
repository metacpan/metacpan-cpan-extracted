#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::TracksBot' ) || print "Bail out!
";
}

diag( "Testing App::TracksBot $App::TracksBot::VERSION, Perl $], $^X" );
