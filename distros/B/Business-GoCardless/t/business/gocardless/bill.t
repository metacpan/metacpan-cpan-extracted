#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Bill' );
isa_ok(
    my $Bill = Business::GoCardless::Bill->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::Bill'
);

can_ok(
    $Bill,
    qw/
        endpoint
        amount
        gocardless_fees
        partner_fees
        amount_minus_fees
        currency
        description
        name
        status
        can_be_retried
        can_be_cancelled
        is_setup_fee
        source_id
        source_type
        merchant_id
        user_id
        payout_id
        created_at
        paid_at
        charge_customer_at
        uri

        retry
        cancel
        refund

        pending
        paid
        failed
        chargedback
        cancelled
        withdrawn
        refunded
    /,
);

is( $Bill->endpoint,'/bills/%s','endpoint' );

$Bill->status( 'unknown' );

ok( ! $Bill->pending,'pending' );
ok( ! $Bill->paid,'paid' );
ok( ! $Bill->failed,'failed' );
ok( ! $Bill->chargedback,'chargedback' );
ok( ! $Bill->cancelled,'cancelled' );
ok( ! $Bill->withdrawn,'withdrawn' );
ok( ! $Bill->refunded,'refunded' );

done_testing();

# vim: ts=4:sw=4:et
