#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use JSON qw/ decode_json /;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Webhook' );
isa_ok(
    my $Webhook = Business::GoCardless::Webhook->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
        json => _json_payload(),
    ),
    'Business::GoCardless::Webhook'
);

can_ok(
    $Webhook,
    qw/
        resource_type
        action
    /,
);

is( $Webhook->resource_type,'bill','resource_type' );
ok( $Webhook->is_bill,'is_bill' );
ok( !$Webhook->is_subscription,'! is_subscription' );
ok( !$Webhook->is_pre_authorization,'! is_pre_authorization' );
is( $Webhook->action,'paid','action' );

cmp_deeply(
    [ $Webhook->resources ],
    [ ( bless( {
        'amount' => '20.0',
        'amount_minus_fees' => '19.8',
        'client' => ignore(),
        'endpoint' => '/bills/%s',
        'id' => ignore(),
        'paid_at' => ignore(),
        'source_id' => ignore(),
        'source_type' => 'subscription',
        'status' => 'paid',
        'uri' => ignore(),
        },'Business::GoCardless::Bill' ) ) x 2
    ],
    'resources'
);

throws_ok(
    sub { $Webhook->json( _json_payload( "bad signature" ) ) },
    'Business::GoCardless::Exception',
    '->json checks signature',
);

ok( ! $Webhook->resources,' ... and clears resources if bad' );

done_testing();

sub _json_payload {

    my ( $signature ) = @_;

    $signature //= 'ae05e1ab577c728593d2670aa40560e62817e0fa482ff748c27bcad7846eace0';

    return qq{{
        "payload": {
            "resource_type": "bill",
            "action": "paid",
            "bills": [
                {
                    "id": "AKJ398H8KA",
                    "status": "paid",
                    "source_type": "subscription",
                    "source_id": "KKJ398H8K8",
                    "amount": "20.0",
                    "amount_minus_fees": "19.8",
                    "paid_at": "2011-12-01T12:00:00Z",
                    "uri": "https://gocardless.com/api/v1/bills/AKJ398H8KA"
                },
                {
                    "id": "AKJ398H8KB",
                    "status": "paid",
                    "source_type": "subscription",
                    "source_id": "8AKJ398H78",
                    "amount": "20.0",
                    "amount_minus_fees": "19.8",
                    "paid_at": "2011-12-09T12:00:00Z",
                    "uri": "https://gocardless.com/api/v1/bills/AKJ398H8KB"
                }
            ],
            "signature": "$signature"
        }
    }};
}

# vim: ts=4:sw=4:et
