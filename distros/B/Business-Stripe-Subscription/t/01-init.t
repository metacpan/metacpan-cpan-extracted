#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Business::Stripe::Subscription;

plan tests => 3;

my $stripe_pass = Business::Stripe::Subscription->new(
    'api_secret'  => 'sk_test_00000000000000000000000000',
    'api_public'  => 'pk_test_00000000000000000000000000',
    'success_url' => 'https://www.example.com/yippee.html',
    'cancel_url'  => 'https://www.example.com/cancelled.html',
);

ok( $stripe_pass->success, "Object instantiated" );

my $stripe_fail = Business::Stripe::Subscription->new(
    'api_secret'  => 'pk_test_00000000000000000000000000',
    'api_public'  => 'sk_test_00000000000000000000000000',
    'success_url' => 'https://www.example.com/yippee.html',
    'cancel_url'  => 'https://www.example.com/cancelled.html',
);

ok( !$stripe_fail->success, "Object failed instantiated" );
is( $stripe_fail->error, 'Secret API key provided is not a valid key', "Correct key error" );



