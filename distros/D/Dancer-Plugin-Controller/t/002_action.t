# -*- perl -*-

# t/002_action.t - check action run

use strict;
use warnings;

use Test::More 'no_plan';

use FindBin;
use lib $FindBin::Bin. '/lib';

use TestApp;
use Dancer::Test appdir => $FindBin::Bin;


response_status_is  [GET => '/'], 200    , "GET / status is 200";
response_content_is [GET => '/'], 'Hello', "GET / content";

response_status_is            [GET => '/404_redirect_test'], 302, "GET /404_redirect_test status is 302";
response_redirect_location_is [GET => '/404_redirect_test'], 'http://localhost/404', "GET /404_redirect_test location";

response_status_is  [GET => '/inherit'], 200      , "GET /inherit status is 200";
response_content_is [GET => '/inherit'], 'x_value', "GET /inherit content";

response_status_is  [GET => '/custom_action_method'], 200            , "GET /custom_action_method status is 200";
response_content_is [GET => '/custom_action_method'], 'custom_method', "GET /custom_action_method content";
