#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Box2D' ) || print "Bail out!
";
}

diag( "Testing Box2D $Box2D::VERSION, Perl $], $^X" );
