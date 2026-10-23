#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::PaymentAccount' );
isa_ok(
    my $Account = Business::GoCardless::PaymentAccount->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::PaymentAccount'
);

can_ok(
    $Account,
    qw/
        endpoint
        account_balance
        account_holder_name
        account_number_ending
        bank_name
        currency
        id
        links
    /,
);

is( $Account->endpoint,'/payment_accounts/%s','endpoint' );
is( $Account->uri,'https://api.gocardless.com/payment_accounts/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
