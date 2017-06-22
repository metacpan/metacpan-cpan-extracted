#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Authen::TuringImage' ) || print "Bail out!
";
}

diag( "Testing Authen::TuringImage $Authen::TuringImage::VERSION, Perl $], $^X" );
