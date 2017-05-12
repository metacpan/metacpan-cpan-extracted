use strict;
use warnings;
use Test::More tests => 7;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test_render?template=specified_template.tt&param=parameterized"))->is_success, 'request ok');
is($response->content, "I should be a parameterized test in @{[TestApp->config->{name}]}", 'message ok');

my $message = 'Dynamic message';

ok(($response = request("/test_msg?msg=$message"))->is_success, 'request ok');
is($response->content, "$message", 'message ok');

$response = request("/test_render?template=non_existant_template.tt");

is (403, $response->code, 'request returned error');
is($response->content, 'file error - non_existant_template.tt: not found', 'Error from non-existant-template');
