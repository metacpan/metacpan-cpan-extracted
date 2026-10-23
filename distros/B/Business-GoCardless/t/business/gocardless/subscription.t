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
        app_fee
        count
        created_at
        currency
        description
        earliest_charge_date_after_resume
        expires_at
        id
        interval_length
        interval_unit
        merchant_id
        name
        next_interval_start
        parent_plan_paused
        retry_if_possible
        setup_fee
        status
        uri
        user_id

        cancel

        pending_customer_approval
        customer_approval_denied
        inactive
        active
        finished
        cancelled
        paused
        expired
    /,
);

is( $Subscription->endpoint,'/subscriptions/%s','endpoint' );

$Subscription->status( 'unknown' );

ok( ! $Subscription->pending_customer_approval,'pending_customer_approval' );
ok( ! $Subscription->customer_approval_denied,'customer_approval_denied' );
ok( ! $Subscription->inactive,'inactive' );
ok( ! $Subscription->active,'active' );
ok( ! $Subscription->finished,'finished' );
ok( ! $Subscription->cancelled,'cancelled' );
ok( ! $Subscription->paused,'paused' );
ok( ! $Subscription->expired,'expired' );

done_testing();

# vim: ts=4:sw=4:et
