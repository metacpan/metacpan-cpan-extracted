#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Business::Bitpay;
use JSON 'decode_json';

my $api_key = 'someapikey';
my $bitpay  = new_ok 'Business::Bitpay', [$api_key];
my $data    = {price => 15, currency => 'USD'};

subtest 'POST request' => sub {
    my $request = $bitpay->prepare_request('invoice', $data);
    is $request->method, 'POST', 'method';
    is $request->uri, "https://$api_key:\@bitpay.com/api/invoice", 'uri';
    is $request->header('content-type'), 'application/json', 'content type';
    is $request->header('X-BitPay-Plugin-Info'),
      'perl' . $Business::Bitpay::VERSION, 'plugin info header';
    is_deeply decode_json($request->content), $data, 'data';
};

subtest 'GET request' => sub {
    my $request = $bitpay->prepare_request('invoice/id');
    is $request->method, 'GET', 'method';
    is $request->uri, "https://$api_key:\@bitpay.com/api/invoice/id", 'uri';
};

done_testing();
