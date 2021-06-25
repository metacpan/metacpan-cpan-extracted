use strict;
use warnings;

use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use lib 'lib', 't/lib';

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'endpoint';
}
use TestApp;

my $app  = TestApp->to_app;
my $test = Plack::Test->create($app);

ok $test->request( GET '/' ), "GET / so we have HTTP_OK metrics";

my $res = $test->request( GET '/metrics' );
is $res->code, 404, "default endpoint /metrics NOT_FOUND";

$res = $test->request( GET '/test-metrics' );
is $res->code, 200, "endpoint /test-metrics OK";

like $res->content, qr/http_requests_total\{code="200",method="GET"\} 1/,
  "... and we see OK request in metrics";

like $res->content, qr/http_requests_total\{code="404",method="GET"\} 1/,
  "... and we see NOT_FOUND request in metrics";

done_testing;
