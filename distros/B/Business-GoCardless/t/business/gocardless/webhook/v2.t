#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use JSON qw/ decode_json /;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Webhook::V2' );
isa_ok(
    my $Webhook = Business::GoCardless::Webhook::V2->new(
        client => Business::GoCardless::Client->new(
            token          => 'foo',
            webhook_secret => 'bar',
        ),
        json => _json_payload(),
        _signature => 'd83ab95b082ac2d0154060fe63530723104d55249b00f1b49019859cbcd51078',
    ),
    'Business::GoCardless::Webhook::V2'
);

can_ok(
    $Webhook,
    qw/
        resource_type
        action
    /,
);

ok( !$Webhook->is_legacy,'! ->is_legacy' );
ok( my $events = $Webhook->events,'->events' );
cmp_deeply(
    $events->[2],
    bless( {
        'action' => 'paid_out',
        'client' => bless( {
          'api_version' => 1,
          'base_url' => 'https://gocardless.com',
          'token' => 'foo',
          'user_agent' => ignore(),
          'webhook_secret' => 'bar'
        }, 'Business::GoCardless::Client' ),
        'created_at' => '2017-09-11T14:05:35.461Z',
        'endpoint' => '/events/%s',
        'id' => 'EV789',
        'links' => {
          'parent_event' => 'EV123',
          'payment' => 'PM456',
          'payout' => 'PO123'
        },
        'details' => {
          'cause' => 'payment_paid_out',
          'description' => 'The payment has been paid out by GoCardless.',
          'origin' => 'gocardless'
        },
        'resource_type' => 'payments'
      }, 'Business::GoCardless::Webhook::Event'
    ),
    'more than one event'
);

$Webhook->signature( 'bad signature' );

throws_ok(
    sub { $Webhook->json( _json_payload() ) },
    'Business::GoCardless::Exception',
    '->json checks signature',
);

ok( ! $Webhook->resources,' ... and clears resources if bad' );

isa_ok(
    $Webhook = Business::GoCardless::Webhook::V2->new(
        client => Business::GoCardless::Client->new(
            token          => 'foo',
            webhook_secret => 'baz',
        ),
        json => _json_payload_legacy(),
    ),
    'Business::GoCardless::Webhook::V2'
);

ok( $Webhook->has_legacy_data,'->has_legacy_data' );
isa_ok( $Webhook = $Webhook->legacy_webhook,'Business::GoCardless::Webhook' );
is( $Webhook->resource_type,'bill','resource_type' );
ok( $Webhook->is_bill,'is_bill' );
ok( !$Webhook->is_subscription,'! is_subscription' );
ok( !$Webhook->is_pre_authorization,'! is_pre_authorization' );
is( $Webhook->action,'paid','action' );
ok( $Webhook->is_legacy,'->is_legacy' );

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

done_testing();

sub _json_payload {

    my ( $signature ) = @_;

    $signature //= 'd83ab95b082ac2d0154060fe63530723104d55249b00f1b49019859cbcd51078';

    return qq!{
   "events" : [
      {
         "action" : "paid",
         "created_at" : "2017-09-11T14:05:35.414Z",
         "details" : {
            "cause" : "payout_paid",
            "description" : "GoCardless has transferred the payout to the creditor's bank account.",
            "origin" : "gocardless"
         },
         "id" : "EV123",
         "links" : {
            "payout" : "PO123"
         },
         "metadata" : {},
         "resource_type" : "payouts"
      },
      {
         "action" : "paid_out",
         "created_at" : "2017-09-11T14:05:35.453Z",
         "details" : {
            "cause" : "payment_paid_out",
            "description" : "The payment has been paid out by GoCardless.",
            "origin" : "gocardless"
         },
         "id" : "EV456",
         "links" : {
            "parent_event" : "EV123",
            "payment" : "PM123",
            "payout" : "PO123"
         },
         "metadata" : {},
         "resource_type" : "payments"
      },
      {
         "action" : "paid_out",
         "created_at" : "2017-09-11T14:05:35.461Z",
         "details" : {
            "cause" : "payment_paid_out",
            "description" : "The payment has been paid out by GoCardless.",
            "origin" : "gocardless"
         },
         "id" : "EV789",
         "links" : {
            "parent_event" : "EV123",
            "payment" : "PM456",
            "payout" : "PO123"
         },
         "metadata" : {},
         "resource_type" : "payments"
      }
   ]
}!;
}

sub _json_payload_legacy {

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
