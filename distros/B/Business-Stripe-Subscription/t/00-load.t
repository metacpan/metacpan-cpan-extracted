#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Business::Stripe::Subscription' ) || print "Bail out!\n";
}

diag( "Testing Business::Stripe::Subscription $Business::Stripe::Subscription::VERSION, Perl $], $^X" );
