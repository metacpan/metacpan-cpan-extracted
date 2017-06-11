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
        _signature => '07525beb4617490b433bd9036b97e856cefb041a6401e4f18b228345d34f5fc5',
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

cmp_deeply(
    $Webhook->events,
    [
      bless( {
        'action' => 'paid',
        'client' => bless( {
          'api_version' => 1,
          'base_url' => 'https://gocardless.com',
          'token' => 'foo',
          'user_agent' => ignore(),
          'webhook_secret' => 'bar'
        }, 'Business::GoCardless::Client' ),
        'created_at' => '2014-08-04T12:00:00.000Z',
        'endpoint' => '/events/%s',
        'id' => 'EV123',
        'links' => {
          'payout' => 'PO123'
        },
        'resource_type' => 'payouts'
      }, 'Business::GoCardless::Webhook::Event' )
    ],
    'events'
);

$Webhook->signature( 'bad signature' );

throws_ok(
    sub { $Webhook->json( _json_payload() ) },
    'Business::GoCardless::Exception',
    '->json checks signature',
);

ok( ! $Webhook->resources,' ... and clears resources if bad' );

done_testing();

sub _json_payload {

    my ( $signature ) = @_;

    $signature //= '07525beb4617490b433bd9036b97e856cefb041a6401e4f18b228345d34f5fc5';

    return qq!{
  "events": [
    {
      "id": "EV123",
      "created_at": "2014-08-04T12:00:00.000Z",
      "action": "paid",
      "resource_type": "payouts",
      "links": {
        "payout": "PO123"
      }
    }
  ]
}!;
}

# vim: ts=4:sw=4:et
