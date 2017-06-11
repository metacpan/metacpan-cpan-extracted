#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::RedirectFlow' );
isa_ok(
    my $RedirectFlow = Business::GoCardless::RedirectFlow->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::RedirectFlow'
);

can_ok(
    $RedirectFlow,
    qw/
        created_at
        currency
        description
        expires_at
        id
        interval_length
        interval_unit
        max_amount
        merchant_id
        name
        next_interval_start
        remaining_amount
        setup_fee
        status
        uri
        user_id

        cancel

        inactive
        active
        cancelled
        expired
    /,
);

is( $RedirectFlow->endpoint,'/redirect_flows/%s','endpoint' );

$RedirectFlow->status( 'unknown' );

ok( ! $RedirectFlow->inactive,'inactive' );
ok( ! $RedirectFlow->active,'active' );
ok( ! $RedirectFlow->cancelled,'cancelled' );
ok( ! $RedirectFlow->expired,'expired' );

throws_ok(
    sub { $RedirectFlow->cancel },
    'Business::GoCardless::Exception',
    "->cancel on a RedirectFlow is not meaningful in the Pro API",
);

done_testing();

# vim: ts=4:sw=4:et
