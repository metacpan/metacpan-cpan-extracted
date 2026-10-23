#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::PayoutItem' );
isa_ok(
    my $Item = Business::GoCardless::PayoutItem->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        links  => {
            mandate => 'MD123',
            payment => 'PM123',
            refund  => 'RF123',
        },
    ),
    'Business::GoCardless::PayoutItem'
);

can_ok(
    $Item,
    qw/
        endpoint
        amount
        links
        taxes
        type

        mandate_id
        payment_id
        refund_id
    /,
);

is( $Item->endpoint,'/payout_items/%s','endpoint' );

note( "links" );

is( $Item->mandate_id,'MD123','->mandate_id' );
is( $Item->payment_id,'PM123','->payment_id' );
is( $Item->refund_id,'RF123','->refund_id' );

$Item->links( undef );
ok( ! $Item->mandate_id,'! ->mandate_id when no links' );

done_testing();

# vim: ts=4:sw=4:et
