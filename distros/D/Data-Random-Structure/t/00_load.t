#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Random::Structure' ) || print "Bail out!\n";
}

diag( "Testing Data::Random::Structure $Data::Random::Structure::VERSION, Perl $], $^X" );
