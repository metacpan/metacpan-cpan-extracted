#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Dancer::OO::Dancer' ) || print "Bail out!\n";
    use_ok( 'Dancer::OO::Object' ) || print "Bail out!\n";
}

diag( "Testing Dancer::OO::Dancer $Dancer::OO::Dancer::VERSION, Perl $], $^X" );
