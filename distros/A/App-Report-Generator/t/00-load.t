#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Report::Generator' ) || print "Bail out!
";
}

diag( "Testing App::Report::Generator $App::Report::Generator::VERSION, Perl $], $^X" );
