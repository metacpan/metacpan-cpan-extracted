#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Model::Net::Stripe' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Model::Net::Stripe $Catalyst::Model::Net::Stripe::VERSION, Perl $], $^X" );
