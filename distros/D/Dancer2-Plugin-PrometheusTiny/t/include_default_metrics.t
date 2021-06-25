use strict;
use warnings;

use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use lib 'lib', 't/lib';

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'include_default_metrics';
}
use TestApp;

my $app  = TestApp->to_app;
my $test = Plack::Test->create($app);

ok $test->request( GET '/' ), "GET / so we have HTTP_OK metrics";

my $res = $test->request( GET '/metrics' );
is $res->code, 200, "GET /metrics OK with include_default_metrics false";

for my $metric (
    qw/ http_request_duration_seconds http_request_size_bytes http_requests_total http_response_size_bytes /
  )
{
    unlike $res->content,
      qr/$metric/, "... and we don't see $metric in response content";
}

done_testing;
