use strict;
use Test::More tests => 16;
use Test::Exception;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;
use Test::Fake::HTTPD;
use JSON::Parse 'parse_json';
use JSON 'decode_json';
use Business::OnlinePayment::BitPay::KeyUtils;
use URI;
use lib 'lib';

BEGIN{
    my $tokensResponse = '{"data":[{"policies":[{"policy":"id", "method":"inactive", "params":["TfFkHfxvFx7wvLtnqrudrZRqPEuwCpE8X9L"]}], "token":"DCvbrN5iXzo4X4s4bgBiDjS624o72MVQfacoghGWhCqz", "dateCreated":1436809787782, "pairingExpiration":1436896187782, "pairingCode":"Hgi0Tys"}]}';
    my $paircodeResponse = '{"data":[{"policies":[{"policy":"id", "method":"require", "params":["TfLAXsWtvWpSgqMYjJ1QvJEx2Bdob1mDeK4"]}], "resource":"Gd1q7mZJQU5zGoHAFsh1bmYEcWYQnzHZW6sjWatxtEr2", "token":"9nYwJ7KRRAcH1rXwJZRonXYrJJjcwAUowTC63UVLSYaC", "facade":"pos", "dateCreated":1437686344635}]}';
    my $invoiceResponse = '{"facade":"pos/invoice", "data": {"url":"https://paul.bp:8088/invoice?id=FAdAZK8FwmHyUZSzRvT9GW", "status":"new", "btcPrice":"0.035314", "btcDue":"0.035314", "price":10, "currency":"USD", "exRates":{"USD":283.1700000000001}, "invoiceTime":1438785236697, "expirationTime":1438786136697, "currentTime":1438785236722, "guid":"0b8ab24e-e969-4958-93f6-91ffbe7bf353", "id":"FAdAZK8FwmHyUZSzRvT9GW", "btcPaid":"0.000000", "rate":283.17, "exceptionStatus":false, "paymentUrls": {"BIP21":"bitcoin:midqobEVXi4gpWXqEKQEVZKyiHU653r9Ka?amount=0.035314", "BIP72":"bitcoin:midqobEVXi4gpWXqEKQEVZKyiHU653r9Ka?amount=0.035314&r=https://paul.bp:8088/i/FAdAZK8FwmHyUZSzRvT9GW", "BIP72b":"bitcoin:?r=https://paul.bp:8088/i/FAdAZK8FwmHyUZSzRvT9GW", "BIP73":"https://paul.bp:8088/i/FAdAZK8FwmHyUZSzRvT9GW"}, "token":"21377jk8HujNGhm5Q4vymcGzzint1PaagqUrPPQdGhW6upJhCwrDTc5pztqRkBH4VW"}}';
    my $getTokens = '{"data": [{"pos/invoice":"7zjXTgeWaTj7xXNBA1qV7iBGGHJZNiLjPXNquHdk8BUN"}, {"pos":"HwC497kDGihPFUDiPfbedj6etbrVHyKQaiFHPGspYHHV"}]}';
    my $httpd = run_http_server {
        my $request = shift;
        my $decoded = decode_json($request->content) if $request->content;
        my $uri = $request->uri;
        my $method = $request->method;
        if ($uri->path eq '/postthis') {
        }
        return do {
            if ($method eq "POST") {
                if( $uri->path eq '/postthis' && $decoded->{"token"} && $decoded->{"facade"} ) {
                    [
                        200,
                        [ 'Content-Type' => 'application/json' ],
                        [ '{"facade":"correct", "token":"correct"}']
                    ]
                } elsif( $decoded->{"pairingCode"} && $uri->path eq '/tokens' ) {
                    [
                        200,
                        [ 'Content-Type' => 'application/json' ],
                        [ $paircodeResponse ]
                    ]
                } elsif( $uri->path eq '/tokens' ){
                    [
                        200,
                        [ 'Content-Type' => 'application/json' ],
                        [ $tokensResponse ]
                    ]
                } elsif( $uri->path eq '/invoices' ){
                    [
                        200,
                        [ 'Content-Type' => 'application/json' ],
                        [ $invoiceResponse ]
                    ]
                } else {
                    [
                        500,
                        [ 'Content-Type' => 'application/json' ],
                        [ '{"error":"something has certainly gone wrong"}' ]
                    ]
                }
            } elsif ($method eq "GET") {            
                if( $uri->path eq '/tokens' ){
                    [
                        200,
                        [ 'Content-Type' => 'application/json' ],
                        [ $getTokens ]
                    ]
                } elsif ($uri->path eq '/getthis') {
                    [
                        200,
                        [ 'Content-Type' => 'application/json' ],
                        [ '{"hello":"world"}']
                    ]
                } else {
                    [
                        500,
                        [ 'Content-Type' => 'application/json' ],
                        [ '{"error":"something has certainly gone wrong"}' ]
                    ]
                }
            }
        }
    };

    my $uri = URI->new( $httpd->endpoint );

    my $string = "astring";
    my $pem = Business::OnlinePayment::BitPay::KeyUtils::bpGeneratePem();
    my %opt = ("pem" => $pem);
    $opt{"apiUri"} = $uri;
    use_ok('Business::OnlinePayment::BitPay::Client');
    ok(Business::OnlinePayment::BitPay::Client->new(%opt), "accept new with pem passed");
    throws_ok(sub { Business::OnlinePayment::BitPay::Client->new() }, qr/no pem passed to constructor/, "catches no pem passed to constructor");
    my $client = Business::OnlinePayment::BitPay::Client->new(%opt);
    my @response = $client->pair_client;
    my $pairing = shift(shift(@response))->{'pairingCode'};
    is($pairing, "Hgi0Tys", "retrieves token data from endpoint"); 
    my @response = $client->pair_client(pairingCode => "abcDeF7");
    my $facade = shift(shift(@response))->{'facade'};
    is($facade, "pos", "connects pairing code");
    @response = $client->pair_pos_client("abcDeF7");
    $facade = shift(shift(@response))->{'facade'};
    is($facade, "pos", "connects pairing code");
    my $response = $client->post(path => "tokens", params => {});
    my @data = $client->process_response($response);
    my $code = shift(shift(@data))->{'pairingCode'};
    is($code, "Hgi0Tys", "processes response to data array");
    my $params = {token => "thisisatoken", facade => "pos"};
    my $response = $client->post(path => "postthis", params => $params);
    is($response->content, '{"facade":"correct", "token":"correct"}', "post formatted correctly");
    $client->pair_client(facade => "pos");
    throws_ok(sub { $client->pair_pos_client("abc2") }, qr/Pairing Code is not legal/, "catches incorrect pairing code");
    throws_ok(sub { $client->pair_pos_client("abc2eFGG") }, qr/Pairing Code is not legal/, "catches incorrect pairing code");
    throws_ok(sub { $client->post(path => "badendpoint", params => {}) }, qr/500: something has certainly gone wrong/, "passes along server errrors");
    throws_ok(sub { $client->create_invoice(price => 10, currency => "ASDF") }, qr/BitPay Error: Currency is invalid/, "checks for valid currency");
    throws_ok(sub { $client->create_invoice(price => "ten", currency => "ASD") }, qr/BitPay Error: Price must be formatted as a float/, "checks for valid price");
    throws_ok(sub { $client->get_invoice(id => 12345) }, qr/500: something has certainly gone wrong/, "catches server errors on get requests");
    ok( $client->create_invoice(price => 10, currency => "USD", params => {}), "accepts valid invoice parameters");
    my %invoice = $client->create_invoice(price => 10, currency => "USD", params => {});
    is(%invoice->{'rate'}, 283.17, "create invoice calls endpoint and processes response"); 

}

