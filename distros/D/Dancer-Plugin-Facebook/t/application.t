#!/usr/bin/perl

use Test::More;
use Dancer::Test appdir => '..';
use Dancer qw{:tests};

plan tests => 5;

set errors => 1;
set logger => "file";
set warnings => 1;
debug "Testing non-auth case";

{
    package FBTestApp;
    use Dancer qw{:syntax};
    use Dancer::Plugin::Facebook;
    get '/perl' => sub { fb->fetch ('16665510298')->{name} };
    setup_fb;
    1;
}

route_exists       [GET => '/perl'], "GET /perl endpoint exists";
route_doesnt_exist [GET => '/auth/facebook'], "GET /auth/facebook endpoint does not exist";
route_doesnt_exist [GET => '/auth/facebook/postback'], "GET /auth/facebook/postback endpoint does not exist";

my $response = dancer_response GET => '/perl';
debug "Response is ", $response;
is $response->status, 200, "GET /perl succeeded";
like $response->content, qr,perl,, "GET /perl produced expected output";

done_testing;
