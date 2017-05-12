#!perl

use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response = request('/test');

ok($response->is_success, 'request ok');
is($response->header('content-type'), 'text/html; charset=utf-8', 'default content type ok');

$response = request('/test_content_type');
ok($response->is_success, 'request ok');
is($response->header('content-type'), 'text/html; charset=iso8859-1', 'content type ok');
