use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'HTTP::Request::Common';
use HTTP::Message::PSGI;
use HTTP::Response;
use HTTP::Request::Common;

{
    package sandbox;
    use Amon2::Lite;
    get '/' => sub {
        my $c = shift;
        $c->create_response(200, [], ['get']);
    };
    post '/' => sub {
        my $c = shift;
        $c->create_response(200, [], ['post']);
    };
    get '/get_only' => sub {
        my $c = shift;
        $c->create_response(200, [], ['get']);
    };
}
my $app = sandbox->to_app;
subtest 'GET /' => sub {
    my $res = res_from_psgi($app->(req_to_psgi( GET 'http://localhost/')));
    is($res->code, 200);
    is($res->content, 'get');
};
subtest 'POST /' => sub {
    my $res = res_from_psgi($app->(req_to_psgi(POST 'http://localhost/')));
    is($res->code, 200);
    is($res->content, 'post');
};
subtest 'GET /get_only' => sub {
    my $res = res_from_psgi($app->(req_to_psgi(GET 'http://localhost/get_only')));
    is($res->code, 200);
};
subtest 'POST /get_only' => sub {
    my $res = res_from_psgi($app->(req_to_psgi(POST 'http://localhost/get_only')));
    is($res->code, 405);
};
subtest 'GET /not_found' => sub {
    my $res = res_from_psgi($app->(req_to_psgi(POST 'http://localhost/not_found')));
    is($res->code, 404);
};

done_testing;

