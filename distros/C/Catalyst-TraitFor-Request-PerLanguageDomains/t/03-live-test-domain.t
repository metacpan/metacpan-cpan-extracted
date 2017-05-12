#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use HTTP::Request::Common;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';
my ($res, $c);

ok(request('/')->is_success, 'Get /');

($res, $c) = ctx_request(GET 'http://localhost/get_lang', 'Host'=>'en.test.vhost' );
like($c->res->body, qr/en/, 'Check for language when using language domain en');

($res, $c) = ctx_request(GET 'http://localhost/get_lang', 'Host'=>'de.test.vhost' );
like($c->res->body, qr/de/, 'Check for language when using language domain de');

