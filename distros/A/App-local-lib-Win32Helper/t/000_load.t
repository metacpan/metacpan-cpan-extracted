#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::local::lib::Win32Helper' ) || print "Bail out!
";
}

diag( "Testing App::local::lib::Win32Helper $App::local::lib::Win32Helper::VERSION, Perl $], $^X" );
