#!/usr/bin/env perl
use Dancer;
use tagtest;
use Test::More;
use Dancer::Test;

response_status_is [GET => '/'], 200, "GET / is found";
response_content_like [GET => '/'], qr(<input type="submit"), "content looks good for submit";

done_testing();
