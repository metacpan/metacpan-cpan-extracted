#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Circle::Common' ) || print "Bail out!\n";
}

diag( "Testing Circle::Common $Circle::Common::VERSION, Perl $], $^X" );
