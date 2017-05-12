#!perl

use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response = request('/render?template=foo&param=foo');
ok($response->is_success, 'request ok');
like($response->content, qr/param: foo/, 'message ok');

$response = request('/render?template=does_not_exist');
ok(!$response->is_success, 'request ok');
like($response->content, qr{could not find component for initial path '/does_not_exist'}, 'message ok');
