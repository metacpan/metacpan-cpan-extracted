#!perl
use strict;
use warnings;
use Test::More import => ['!pass'];

unless ($ENV{HAVE_TEST_MEMCACHED_SERVER_LOCALHOST}) {
    plan skip_all =>
        'Env var HAVE_TEST_MEMCACHED_SERVER_LOCALHOST needs set for this test';
}

use_ok('Dancer::Plugin::MemcachedFast');
use lib 't';
use Dancer::Test appdir => '..';
use Dancer;

{

    package MFONTANITestApp;
    use strict;
    use warnings;
    use Dancer ':syntax';
    use Dancer::Plugin::MemcachedFast;
    get '/'               => sub {'Module loaded'};
    get '/get_test'       => sub { memcached_get('data') };
    get '/delete_test'    => sub { memcached_delete('data') };
    get '/set_test/:data' => sub { memcached_set('data', params->{data}) };
    1;
}

my $time = time;    # test value

my $response;

route_exists        [GET => '/'], "GET / handled";
response_status_is  [GET => '/'], 200, "GET / 200";
response_content_is [GET => '/'], "Module loaded", "Correct response received";

route_exists        [GET => '/get_test'], "GET /get_test handled";
response_status_is  [GET => '/get_test'], 200, "GET /get_test 200";
response_content_is [GET => '/get_test'], "", "Correct response received";

$response = dancer_response GET => "/set_test/$time";
is($response->{status},  200, "200 OK for /set_test/$time");
is($response->{content}, '1', "Correct response received for /set_test/$time");

$response = dancer_response GET => "/get_test";
is($response->{status},  200,   "200 OK for /get_test");
is($response->{content}, $time, "Correct response received for /get_test");

$response = dancer_response GET => "/get_test";
is($response->{status},  200,   "200 OK for /get_test");
is($response->{content}, $time, "Correct response received for /get_test");

$response = dancer_response GET => "/delete_test";
is($response->{status},  200, "200 OK for /delete_test");
is($response->{content}, '1', "Correct response received for /delete_test");

done_testing;
