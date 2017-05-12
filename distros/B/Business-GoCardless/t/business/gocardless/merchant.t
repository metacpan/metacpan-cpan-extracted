#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Merchant' );

no warnings 'redefine';
no warnings 'once';
*Business::GoCardless::Merchant::BUILD = sub { return shift };

isa_ok(
    my $Merchant = Business::GoCardless::Merchant->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::Merchant'
);

can_ok(
    $Merchant,
    qw/
        endpoint
        balance
        created_at
        description
        email
        eur_balance
        eur_pending_balance
        first_name
        gbp_balance
        gbp_pending_balance
        hide_variable_amount
        id
        last_name
        name
        next_payout_amount
        next_payout_date
        pending_balance
        sub_resource_uris
        uri
    /,
);

is( $Merchant->endpoint,'/merchants/%s','endpoint' );

done_testing();

# vim: ts=4:sw=4:et
