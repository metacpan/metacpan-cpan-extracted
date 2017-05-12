use strict;
use warnings;
use lib "t/dancer/lib";
use TestApp;
use Dancer::Test;
use Test::More tests => 5;

response_content_is [ GET => "/" ]    => "homepage";
response_content_is [ GET => "/foo" ] => "foo",
    "Test string path";
response_content_is [ GET => "/foo/baz" ] => "baz",
    "Test token path";
response_content_is [ POST => "/bar" ] => "bar",
    "Test regexp";
response_status_is [ POST => "/baz" ] => 404,
    "Not found";
