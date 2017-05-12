#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Config::MyConfig2' ) || print "Bail out!\n";
}

diag( "Testing Config::MyConfig2 $Config::MyConfig2::VERSION, Perl $], $^X" );
