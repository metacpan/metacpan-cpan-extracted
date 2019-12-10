#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Payout' );
isa_ok(
    my $Payout = Business::GoCardless::Payout->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::Payout'
);

can_ok(
    $Payout,
    qw/
        endpoint
        amount
        reference
        status

        app_ids
        bank_reference
        paid_at
        transaction_fees

        amount
        arrival_date
        created_at
        currency
        deducted_fees
        fx
        id
        links
        payout_type
        reference
        status

        pending
        paid
    /,
);

is( $Payout->endpoint,'/payouts/%s','endpoint' );

$Payout->status( 'pending' );
ok( $Payout->pending,'->pending' );
ok( ! $Payout->paid,'->paid' );

$Payout->id( 'PO123' );
is( $Payout->uri,'https://gocardless.com/payouts/PO123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
