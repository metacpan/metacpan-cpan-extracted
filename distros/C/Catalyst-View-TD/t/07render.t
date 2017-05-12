use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test_render?template=specified_template&param=parameterized"))->is_success, 'request ok');
is($response->content, "I should be a parameterized test in @{[TestApp->config->{name}]}", 'message ok');

# TD does not support template text passed as a code ref.
# my $message = 'Dynamic message';
# ok(($response = request("/test_msg?msg=$message"))->is_success, 'request ok');
# is($response->content, "$message", 'message ok');

$response = request("/test_render?template=omgwtf");

is ($response->code, 403, 'request returned error');
like($response->content, qr{OMGWTF!}, 'Error from dieing template');
