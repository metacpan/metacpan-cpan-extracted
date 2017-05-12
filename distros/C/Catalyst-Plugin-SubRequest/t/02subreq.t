package main;

use Test::More tests => 21;
use lib 't/lib';
use Catalyst::Test 'TestApp';
use File::stat;
use HTTP::Date;

my $stat = stat($0);

{
    ok( my $response = request('/normal/2'),    'Normal Request'  );
    is( $response->code, 200,                 'OK status code'  );
    is( $response->content, '123',    'Normal request content', );
}

{
    ok( my $response = request('/subtest'),    'Sub Request'     );
    is( $response->code, 200,                 'OK status code'  );
    is( $response->content, '11433',    'Normal request content', );
}

{
    ok( my $response = request('/subtest_params?value=abc'), 'Params Sub Request' );
    is( $response->code, 200, 'OK status code' );
    is( $response->content, '1abc3', 'Normal request content' );
}

{
    ok( my $response = request('/subtest_req'), 'Sub request not stomping original request object' );
    is( $response->code, 200, 'OK status code' );
    is( $response->content, '/subtest_req3', 'Normal request content' );
}

{
    ok( my $response = request('/subtest_full_response'),    'Sub Reuqest returning full response object'  );
    is( $response->code, 200,                 'OK status code'  );
    is( $response->content, '1text/csv3',    'Normal request content', );
}

{
    ok( my $response = request('/subtest_with_params'),    'Sub request with full params'  );
    is( $response->code, 200,                 'OK status code'  );
    is( $response->content, 'foo33',    'Normal request content', );
}

{
    ok( my $response = request('/doublesubtest'),    'Double Sub Request'  );
    is( $response->code, 200,                 'OK status code'  );
    is( $response->content, '1531633',    'Normal Double request content', ); #we get 153 right now
}
