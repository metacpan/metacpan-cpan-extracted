#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Balance' );
isa_ok(
    my $Balance = Business::GoCardless::Balance->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
    ),
    'Business::GoCardless::Balance'
);

can_ok(
    $Balance,
    qw/
        endpoint
        amount
        balance_type
        currency
        last_updated_at
        links
    /,
);

is( $Balance->endpoint,'/balances/%s','endpoint' );

done_testing();

# vim: ts=4:sw=4:et
