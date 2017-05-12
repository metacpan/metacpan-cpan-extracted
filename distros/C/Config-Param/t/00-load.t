#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Config::Param' ) || print "Bail out!\n";
}

diag( "Testing Config::Param $Config::Param::VERSION, Perl $], $^X" );
