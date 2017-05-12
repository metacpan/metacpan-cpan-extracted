use strict;
use warnings;
use Test::More tests => 8;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request('/'))->is_success, '/');
cmp_ok($response->content, 'eq', 'Mock: 100x100', 'component rendered');
cmp_ok($response->header('Content-Type'), 'eq', 'image/png', 'config content type');

ok(($response = request('/as_pdf'))->is_success, '/as_pdf');
cmp_ok($response->header('Content-Type'), 'eq', 'application/pdf', 'override content type');

ok(($response = request('/switch_driver'))->is_success, '/switch_driver');
cmp_ok($response->content, 'eq', 'Mock2: (baz) 101x101', 'component rendered via Mock2');
