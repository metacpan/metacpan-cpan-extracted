#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Circle::Chain' ) || print "Bail out!\n";
    use_ok( 'Circle::Wallet' ) || print "Bail out!\n";
    use_ok('Circle::User') || print "Bail out!\n";
    use_ok('Circle::Block') || print "Bail out!\n";
}

diag( "Testing Circle::Chain $Circle::Chain::VERSION, Perl $], $^X" );
done_testing();
