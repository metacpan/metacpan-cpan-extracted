#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Template::Ctpp2' ) || print "Bail out!
";
}

diag( "Testing Dancer::Template::Ctpp2 $Dancer::Template::Ctpp2::VERSION, Perl $], $^X" );

