#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Collision::2D' ) || print "Bail out!
";
}

diag( "Testing Collision::2D $Collision::2D::VERSION, Perl $], $^X" );
