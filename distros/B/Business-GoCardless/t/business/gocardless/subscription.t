#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Subscription' );
isa_ok(
    my $Subscription = Business::GoCardless::Subscription->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::Subscription'
);

can_ok(
    $Subscription,
    qw/
        amount
        created_at
        currency
        description
        expires_at
        id
        interval_length
        interval_unit
        merchant_id
        name
        next_interval_start
        setup_fee
        status
        uri
        user_id

        cancel

        inactive
        active
        cancelled
        expired
    /,
);

is( $Subscription->endpoint,'/subscriptions/%s','endpoint' );

$Subscription->status( 'unknown' );

ok( ! $Subscription->inactive,'inactive' );
ok( ! $Subscription->active,'active' );
ok( ! $Subscription->cancelled,'cancelled' );
ok( ! $Subscription->expired,'expired' );

done_testing();

# vim: ts=4:sw=4:et
