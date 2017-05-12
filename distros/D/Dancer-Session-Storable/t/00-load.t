#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Session::Storable' ) || print "Bail out!
";
}

diag( "Testing Dancer::Session::Storable $Dancer::Session::Storable::VERSION, Perl $], $^X" );
