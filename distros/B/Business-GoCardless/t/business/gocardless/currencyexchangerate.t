#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::CurrencyExchangeRate' );
isa_ok(
    my $Rate = Business::GoCardless::CurrencyExchangeRate->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
    ),
    'Business::GoCardless::CurrencyExchangeRate'
);

can_ok(
    $Rate,
    qw/
        endpoint
        rate
        source
        target
        time
    /,
);

is( $Rate->endpoint,'/currency_exchange_rates/%s','endpoint' );

done_testing();

# vim: ts=4:sw=4:et
