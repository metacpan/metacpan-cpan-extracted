use strict;
use warnings;

use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Res;

    get '/' => sub { return "homepage" };

    get '/bad_request' => sub { return res 400 => 'You made a bad request' };
}

my $test = Plack::Test->create( TestApp->to_app );

subtest 'get /' => sub {
    plan tests => 2;

    my $res = $test->request( GET "/" );

    ok $res->is_success, "get / is OK";

    is $res->code, 200, "get / code is 200";
};

subtest 'get /bad_request' => sub {
    plan tests => 3;

    my $res = $test->request( GET "/bad_request" );

    ok !$res->is_success, "get /bad_request is not OK";

    is $res->code, 400, "get /bad_request code is 400";

    is $res->content, "You made a bad request", "content is correct";
};

