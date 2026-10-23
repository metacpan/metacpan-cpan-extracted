#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use JSON qw/ decode_json /;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Webhook::Event' );
isa_ok(
    my $Event = Business::GoCardless::Webhook::Event->new(
        client => Business::GoCardless::Client->new(
            token          => 'foo',
            webhook_secret => 'bar',
        ),
        'id' => 'EV123',
        'created_at' => '2014-08-04T12:00:00.000Z',
        'action' => 'paid',
        'resource_type' => 'payments',
        'links' => {
          'payout' => 'PO123'
        },
    ),
    'Business::GoCardless::Webhook::Event'
);

can_ok(
    $Event,
    qw/
        id
        created_at
        action
        resource_type
        links
        details
    /,
);

isa_ok(
    $Event->resources,
    'Business::GoCardless::Payment',
    '->resources'
);

ok( $Event->is_payment,'is_payment' );
ok( $Event->is_bill,'is_bill' );
ok( !$Event->is_subscription,'! is_subscription' );
ok( !$Event->is_payout,'! is_payout' );
ok( !$Event->is_mandate,'! is_mandate' );
ok( !$Event->is_refund,'! is_refund' );
ok( !$Event->is_pre_authorization,'! is_authorization' );

ok( $Event->resources->payout_id,'payout_id' );

foreach my $t (
    [ refunds   => refund   => 'RF123' => 'Business::GoCardless::Refund' ],
    [ customers => customer => 'CU123' => 'Business::GoCardless::Customer' ],
    [ payouts   => payout   => 'PO123' => 'Business::GoCardless::Payout' ],
) {
    my ( $resource_type,$link,$id,$class ) = @{ $t };

    my $OtherEvent = Business::GoCardless::Webhook::Event->new(
        client        => $Event->client,
        id            => 'EV456',
        created_at    => '2014-08-04T12:00:00.000Z',
        action        => 'created',
        resource_type => $resource_type,
        links         => { $link => $id },
    );

    isa_ok( my $Resource = $OtherEvent->resources,$class,"->resources ($resource_type)" );
    is( $Resource->id,$id,"->resources ($resource_type) id" );
}

ok(
    Business::GoCardless::Webhook::Event->new(
        client        => $Event->client,
        id            => 'EV789',
        created_at    => '2014-08-04T12:00:00.000Z',
        action        => 'created',
        resource_type => 'customers',
        links         => { customer => 'CU123' },
    )->is_customer,
    'is_customer'
);
ok( ! $Event->is_customer,'! is_customer' );

done_testing();

# vim: ts=4:sw=4:et
