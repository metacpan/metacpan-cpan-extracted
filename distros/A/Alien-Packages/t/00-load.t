#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::Packages' ) || print "Bail out!
";
}

diag( "Testing Alien::Packages $Alien::Packages::VERSION, Perl $], $^X" );
