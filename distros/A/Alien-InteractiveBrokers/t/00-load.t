#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::InteractiveBrokers' ) || print "Bail out!
";
}

diag( "Testing Alien::InteractiveBrokers $Alien::InteractiveBrokers::VERSION, Perl $], $^X" );
