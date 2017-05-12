#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Config::Strict' ) || print "Bail out!
";
}

diag( "Testing Config::Strict $Config::Strict::VERSION, Perl $], $^X" );
