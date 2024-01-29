#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Payment' );
isa_ok(
    my $Payment = Business::GoCardless::Payment->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
			api_version => 2,
        ),
        links => {
            mandate => 'MD123',
            payout => 'PO456',
            creditor => 'CR001',
        },
    ),
    'Business::GoCardless::Payment'
);

can_ok(
    $Payment,
    qw/
        endpoint
        amount
        amount_refunded
        charge_date
        created_at
        currency
        description
        fx
        id
        links
        metadata
        reference
        status

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
        submitted
        confirmed
    /,
);

is( $Payment->endpoint,'/payments/%s','endpoint' );

$Payment->status( 'unknown' );

ok( ! $Payment->pending,'pending' );
ok( ! $Payment->paid,'paid' );
ok( ! $Payment->failed,'failed' );
ok( ! $Payment->chargedback,'chargedback' );
ok( ! $Payment->cancelled,'cancelled' );
ok( ! $Payment->withdrawn,'withdrawn' );
ok( ! $Payment->refunded,'refunded' );
ok( ! $Payment->submitted,'submitted' );
ok( ! $Payment->confirmed,'confirmed' );

$Payment->id( 123 );
is( $Payment->uri,'https://api.gocardless.com/payments/123','->uri' );

is( $Payment->payout_id,'PO456','->payout_id' );
is( $Payment->mandate_id,'MD123','->mandate_id' );
is( $Payment->creditor_id,'CR001','->creditor_id' );

done_testing();

# vim: ts=4:sw=4:et
