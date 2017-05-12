#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::podweaver' ) || print "Bail out!
";
}

diag( "Testing App::podweaver $App::podweaver::VERSION, Perl $], $^X" );
