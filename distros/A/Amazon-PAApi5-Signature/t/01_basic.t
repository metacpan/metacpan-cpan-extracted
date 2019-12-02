use strict;
use warnings;
use Test::More;

use Amazon::PAApi5::Payload;
use Amazon::PAApi5::Signature;

{
    my $payload = Amazon::PAApi5::Payload->new(
        'test-example-22',
    );

    isa_ok $payload, 'Amazon::PAApi5::Payload';

    my $json_payload = $payload->to_json({
        Keywords    => 'Perl',
        SearchIndex => 'All',
        ItemCount   => 2,
        Resources   => [qw/
            ItemInfo.Title
        /],
    });

    like $json_payload, qr/^\{/;
    like $json_payload, qr/\}$/;
    like $json_payload, qr/"PartnerTag":"test-example-22"/;
    like $json_payload, qr/"Marketplace":"www.amazon.com"/;
    like $json_payload, qr/"PartnerType":"Associates"/;
    like $json_payload, qr/"Keywords":"Perl"/;

    my $sig = Amazon::PAApi5::Signature->new(
        'ACCESSKEY',
        'SECRETKEY',
        $json_payload,
    );

    isa_ok $sig, 'Amazon::PAApi5::Signature';

    is $sig->req_url, 'https://webservices.amazon.com/paapi5/searchitems';

    my $auth = $sig->headers_as_hashref->{Authorization};
    like $auth, qr/^AWS4-HMAC-SHA256 Credential=ACCESSKEY\//;
    like $auth, qr/,Signature=[a-f0-9]+$/;

    my $to_req = $sig->to_request;
    is $to_req->{method}, 'POST';
    is $to_req->{uri}, $sig->req_url;
    like $to_req->{headers}{Authorization}, qr/^AWS4-HMAC-SHA256 Credential=ACCESSKEY\//;
    like $to_req->{content}, qr/^\{.+\}$/;
}

done_testing;
