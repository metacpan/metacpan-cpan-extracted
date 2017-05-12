#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Model::Redis' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Model::Redis $Catalyst::Model::Redis::VERSION, Perl $], $^X" );
