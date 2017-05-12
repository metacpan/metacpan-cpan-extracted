use strict;
use Test::More;
use Test::Exception;

use Business::MollieAPI;
use Data::Dumper;
use JSON::XS;

my $api = Business::MollieAPI->new();

dies_ok {
    $api->api_key('hello world');
};

SKIP: {
    skip 'Specify TEST_MOLLIE_TESTMODE_KEY to run tests', 7 unless $ENV{TEST_MOLLIE_TESTMODE_KEY};

    $api->api_key($ENV{TEST_MOLLIE_TESTMODE_KEY});

    my $req = $api->payments->_create_request(
        amount      => '12.34',
        redirectUrl => "http://example.com/test.php",
        description => "Order #123123",
    );

    is($req->method, 'POST');
    is($req->uri, 'https://api.mollie.nl/v1/payments');
    is($req->content_type, 'application/json');

    my $o = decode_json($req->decoded_content);
    is($o->{amount}, "12.34");
    is($o->{redirectUrl}, "http://example.com/test.php");
    is($o->{description}, "Order #123123");

    my $res = $api->payments->create(
        amount      => '12.34',
        redirectUrl => "http://example.com/test.php",
        description => "Order #123123",
        method      => 'ideal',
    );

    my $id = $res->{id};
    my $res2 = $api->payments->get($id);
    is($res2->{amount}, '12.34');
}

done_testing;

