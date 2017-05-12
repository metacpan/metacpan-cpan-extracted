#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::PreAuthorization' );
isa_ok(
    my $PreAuthorization = Business::GoCardless::PreAuthorization->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::PreAuthorization'
);

can_ok(
    $PreAuthorization,
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

is( $PreAuthorization->endpoint,'/pre_authorizations/%s','endpoint' );

$PreAuthorization->status( 'unknown' );

ok( ! $PreAuthorization->inactive,'inactive' );
ok( ! $PreAuthorization->active,'active' );
ok( ! $PreAuthorization->cancelled,'cancelled' );
ok( ! $PreAuthorization->expired,'expired' );

done_testing();

# vim: ts=4:sw=4:et
