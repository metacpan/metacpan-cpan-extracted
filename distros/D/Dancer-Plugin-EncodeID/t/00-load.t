#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::EncodeID' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::EncodeID $Dancer::Plugin::EncodeID::VERSION, Perl $], $^X" );
