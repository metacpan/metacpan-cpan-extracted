use strict;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test_render?template=specified_template.haml&param=parameterized"))->is_success, 'request ok');
is($response->content, '&lt;p&gt;parameterized&lt;/p&gt;', 'message ok');

my $message = 'Dynamic message';

# ok(($response = request("/test_msg?msg=$message"))->is_success, 'request ok');
# is($response->content, "$message", 'message ok');

$response = request("/test_render?template=non_existant_template.haml");

is (403, $response->code, 'request returned error');
like($response->content, qr[Can\'t read], 'Error from non-existant-template');
