#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::Tidyp' ) || print "Bail out!";
}

diag( "Testing Alien::Tidyp $Alien::Tidyp::VERSION, Perl $], $^X" );
