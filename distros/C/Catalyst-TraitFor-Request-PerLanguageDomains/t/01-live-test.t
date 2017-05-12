#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use HTTP::Request::Common;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';
my ($res, $c);

ok(request('/')->is_success, 'Get /');

($res, $c) = ctx_request(GET 'http://localhost/get_lang');
like($c->res->body, qr/de/, 'Check for default language');

my $cookie = $res->header('Set-Cookie');
ok($cookie, 'Have a cookie');

($res, $c) = ctx_request(GET 'http://localhost/set_lang/en', Cookie => $cookie);
like($c->res->body, qr/en/, 'Check for lang en in Session');

($res, $c) = ctx_request(GET 'http://localhost/get_lang');
like($c->res->body, qr/de/, 'Check for default language');

($res, $c) = ctx_request(GET 'http://localhost/set_lang/ab', Cookie => $cookie);
like($c->res->body, qr/de/, 'Fallback to default language when trying bogus language');

