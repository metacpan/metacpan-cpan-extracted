#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::AutoBuild' ) || print "Bail out!
";
}

diag( "Testing App::AutoBuild $App::AutoBuild::VERSION, Perl $], $^X" );
