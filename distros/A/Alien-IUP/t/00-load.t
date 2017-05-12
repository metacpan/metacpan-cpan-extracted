#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::IUP' ) || print "Bail out!
";
}

diag( "Testing Alien::IUP $Alien::IUP::VERSION, Perl $], $^X" );
