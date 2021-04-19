#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

#my $test_count = 22;
#plan tests => $test_count;

BEGIN {
    use_ok( 'Business::Stripe::WebCheckout' ) || print "Bail out!\n";
}

# diag( "Testing Business::Stripe::WebCheckout $Business::Stripe::WebCheckout::VERSION, Perl $], $^X" );

my $stripe = Business::Stripe::WebCheckout->new(
	'api-public'    => 'pk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
	'api-secret'    => 'sk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
	'success-url'   => 'https://www.example.com/yippee.html',
	'cancel-url'    => 'https://www.example.com/ohdear.html',
);

my $intent = $stripe->get_intent;

ok ( !$stripe->success,																		'Failed to get intent as invalid key' );

my $intent_id = $stripe->get_intent_id;

ok ( !$stripe->success,																		'Failed to get intent_id as invalid key' );

my $ids = $stripe->get_ids;

ok ( !$stripe->success,																		'Failed to get ids as invalid key' );

my $checkout = $stripe->checkout;

ok ( !$stripe->success,																		'Failed to generate checkout HTML as invalid key' );

done_testing;
