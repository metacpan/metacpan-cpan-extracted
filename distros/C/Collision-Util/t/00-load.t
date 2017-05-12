#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Collision::Util' ) || print "Bail out!
";
}

diag( "Testing Collision::Util $Collision::Util::VERSION, Perl $], $^X" );
