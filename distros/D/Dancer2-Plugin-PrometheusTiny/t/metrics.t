use strict;
use warnings;

use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use lib 'lib', 't/lib';

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'metrics';
}
use TestApp;

my $app  = TestApp->to_app;
my $test = Plack::Test->create($app);

ok $test->request( GET '/test-metrics' ),
  "GET /test-metrics which sets custom metrics";

my $res = $test->request( GET '/metrics' );
is $res->code, 200, "GET /metrics OK";

like $res->content, qr/http_requests_total\{code="200",method="GET"\} 1/,
  "... and we see a default metric";

my $expect = qr/# HELP test_counter Test Counter
# TYPE test_counter counter
test_counter 5
# HELP test_gauge Test Gauge
# TYPE test_gauge gauge
test_gauge 42
# HELP test_histogram Test Histogram
# TYPE test_histogram histogram
test_histogram_bucket\{le="1"\} 0
test_histogram_bucket\{le="2"\} 1
test_histogram_bucket\{le="3"\} 2/;

like $res->content, $expect,
  "... and we see custom metrics";

done_testing;
