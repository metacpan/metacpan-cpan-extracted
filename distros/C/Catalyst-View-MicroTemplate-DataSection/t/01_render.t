use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test"))->is_success, 'request ok');
is($response->content, 'test', 'message ok');

ok(($response = request("/datasection"))->is_success, 'request ok');
is($response->content, "hello masakyst\n", 'message ok');

done_testing;
