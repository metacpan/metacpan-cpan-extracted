#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;
use HTTP::Request::Common;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';
my ($res, $c);

ok(request('/')->is_success, 'Get /');

($res, $c) = ctx_request(GET 'http://localhost/get_lang', 'Accept-Language'=>'en-us;q=0.8,en;q=0.5,de-de,de;q=0.3' );
like($c->res->body, qr/en/, 'Check for language when sent header for en');

($res, $c) = ctx_request(GET 'http://localhost/get_lang', 'Accept-Language'=>'de-de,de;q=0.8,en-us;q=0.5,en;q=0.3' );
like($c->res->body, qr/de/, 'Check for language when sent header for de');

($res, $c) = ctx_request(GET 'http://localhost/get_lang', 'Accept-Language'=>'en-us;q=0.5,en;q=0.8,de-de,de;q=0.9' );
like($c->res->body, qr/de/, 'Check for language when sent header for de with high q');

($res, $c) = ctx_request(GET 'http://localhost/get_lang', 'Accept-Language'=>'ja;q=0.8,en;q=0.3,de-de,de;q=0.5' );
like($c->res->body, qr/de/, 'Check for language when sent header for de with medium q, unkown lang high q');

