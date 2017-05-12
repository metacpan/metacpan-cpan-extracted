#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Github::Test' ) || print "Bail out!\n";
}

diag( "Testing Acme::GitHub::Test $Acme::Github::Test::VERSION, Perl $], $^X" );
