#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::NoodlePay' ) || print "Bail out!
";
}

diag( "Testing App::NoodlePay $App::NoodlePay::VERSION, Perl $], $^X" );
