#!/usr/bin/perl

use Test::More;
use Dancer::Test appdir => '..';
use Dancer qw{:tests};

plan (($ENV{TESTING_APP_ID} and $ENV{TESTING_SECRET}) ? (tests => 5) : (skip_all => 'TESTING_APP_ID and TESTING_SECRET both need to be set'));

set errors => 1;
set logger => "file";
set warnings => 1;
debug "Testing auth case";

{
    package FBTestApp;
    use Dancer qw{:syntax};
    use Dancer::Plugin::Facebook;
    setting ('plugins')->{Facebook}->{application} = {app_id => $ENV{TESTING_APP_ID}, secret => $ENV{TESTING_SECRET}};
    setup_fb '/auth/facebook';
    1;
}

route_doesnt_exist [GET => '/perl'], "GET /perl endpoint does not exist";
route_exists       [GET => '/auth/facebook'], "GET /auth/facebook endpoint exists";
route_exists       [GET => '/auth/facebook/postback'], "GET /auth/facebook/postback endpoint exists";

my $response = dancer_response GET => '/auth/facebook';
debug "Response is ", $response;
is $response->status, 303, "GET /auth/facebook was redirected";
like $response->header ('Location'), qr,^https://graph.facebook.com,, "GET /auth/facebook was redirected to facebook";

done_testing;
