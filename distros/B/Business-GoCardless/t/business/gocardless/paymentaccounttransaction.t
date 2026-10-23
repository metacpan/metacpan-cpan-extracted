#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::PaymentAccountTransaction' );
isa_ok(
    my $Transaction = Business::GoCardless::PaymentAccountTransaction->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::PaymentAccountTransaction'
);

can_ok(
    $Transaction,
    qw/
        endpoint
        amount
        balance_after_transaction
        counterparty_name
        currency
        description
        direction
        id
        links
        reference
        value_date
    /,
);

is( $Transaction->endpoint,'/payment_account_transactions/%s','endpoint' );
is( $Transaction->uri,'https://api.gocardless.com/payment_account_transactions/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
