#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Monzo::Client;

$Business::Monzo::Resource::client = Business::Monzo::Client->new(
    token      => 'foo',
);

use_ok( 'Business::Monzo::Webhook' );
isa_ok(
    my $Webhook = Business::Monzo::Webhook->new(
        "id"           => "webhook_id_123",
        "callback_url" => "https://foo.bar.com",
        "account"      => 1,
        'client'       => Business::Monzo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Monzo::Webhook'
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
    'Business::Monzo::Exception'
);

is(
    $@->message,
    'Monzo API does not currently support getting webhook data',
    ' ... with expected message'
);

is( $Webhook->url,'https://api.monzo.com/webhooks/webhook_id_123','->url' );

no warnings 'redefine';
*Business::Monzo::Client::api_delete = sub { {} };

ok( $Webhook->delete,'->delete' );

ok( $Webhook->to_hash,'to_hash' );
ok( $Webhook->as_json,'as_json' );
ok( $Webhook->TO_JSON,'TO_JSON' );

done_testing();

# vim: ts=4:sw=4:et
