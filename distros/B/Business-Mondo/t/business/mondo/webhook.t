#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Mondo::Client;

$Business::Mondo::Resource::client = Business::Mondo::Client->new(
    token      => 'foo',
);

use_ok( 'Business::Mondo::Webhook' );
isa_ok(
    my $Webhook = Business::Mondo::Webhook->new(
        "id"           => "webhook_id_123",
        "callback_url" => "https://foo.bar.com",
        "account"      => 1,
        'client'       => Business::Mondo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Mondo::Webhook'
);

can_ok(
    $Webhook,
    qw/
        url
        get
        to_hash
        as_json
        TO_JSON

        id
        callback_url
        account
    /,
);

throws_ok(
    sub { $Webhook->get },
    'Business::Mondo::Exception'
);

is(
    $@->message,
    'Mondo API does not currently support getting webhook data',
    ' ... with expected message'
);

is( $Webhook->url,'https://api.getmondo.co.uk/webhooks/webhook_id_123','->url' );

no warnings 'redefine';
*Business::Mondo::Client::api_delete = sub { {} };

ok( $Webhook->delete,'->delete' );

ok( $Webhook->to_hash,'to_hash' );
ok( $Webhook->as_json,'as_json' );
ok( $Webhook->TO_JSON,'TO_JSON' );

done_testing();

# vim: ts=4:sw=4:et
