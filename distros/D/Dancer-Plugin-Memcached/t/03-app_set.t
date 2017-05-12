#!perl

use strict;
use warnings;

use Test::More import => ['!pass'];

unless ( $ENV{D_P_M_SERVER} )
{
    plan(skip_all => "Environment variable D_P_M_SERVER not set");
}
else
{
    plan(tests => 12);
}

use lib './t';
use_ok 'TestApp';

use Dancer::Test;
use Dancer;

setting plugins => { Memcached => { servers => [ $ENV{D_P_M_SERVER} ] } };

my $time = time;
my $response;

route_exists        [GET => '/'], "GET / is handled";
response_status_is  [GET => '/'], 200, 'response status is 200 for /';
response_content_is [GET => '/'], "Test Module Loaded", 
    "got expected response content for GET /";

$response = dancer_response(GET => '/set_test/'.$time);
is $response->{status}, 200, 'response status is 200 for /set_test';
is $response->{content}, $time, "got expected response content for GET /set_test";

$response = dancer_response(POST => '/get_test', { params => {data => '/set_test/'.$time} });
is $response->{status}, 200, 'response status is 200 for /get_test';
is $response->{content}, $time, "got expected response content for POST /get_test";

$response = dancer_response(POST => '/store_test', { params => { key => 'test', data => $time} });
is $response->{status}, 200, 'response status is 200 for /store_test';
is $response->{content}, $time, "got expected response content for POST /store_test";

$response = dancer_response(GET => '/fetch_stored', { params => { key => 'test' } });
is $response->{status}, 200, 'response status is 200 for /fetch_stored';
is $response->{content}, $time, "got expected response content for GET /fetch_stored";

