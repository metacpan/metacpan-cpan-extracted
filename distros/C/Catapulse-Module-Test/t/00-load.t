#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catapulse::Module::Test' ) || print "Bail out!\n";
}

diag( "Testing Catapulse::Module;;Test $Catapulse::Module::Test::VERSION, Perl $], $^X" );

done_testing();
