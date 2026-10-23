#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::NegativeBalanceLimit' );
isa_ok(
    my $Limit = Business::GoCardless::NegativeBalanceLimit->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::NegativeBalanceLimit'
);

can_ok(
    $Limit,
    qw/
        endpoint
        balance_limit
        created_at
        currency
        id
        links
    /,
);

is( $Limit->endpoint,'/negative_balance_limits/%s','endpoint' );
is( $Limit->uri,'https://api.gocardless.com/negative_balance_limits/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
