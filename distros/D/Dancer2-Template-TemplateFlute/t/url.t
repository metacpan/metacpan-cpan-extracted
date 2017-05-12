use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Builder;

{

    package TestApp;
    use Dancer2;

    get '/' => sub {
        template url => {};
    };
}

subtest "app mounted on default /" => sub {

    my $test = Plack::Test->create( TestApp->to_app );

    my $res = $test->request( GET '/' );
    ok $res->is_success, "GET /successful";

    like $res->content, qr{<a href="/old/href">some link},
      "link href not changed";

    like $res->content, qr{<img src="/old/img"}, "img src not changed";

};

subtest "app mounted on /foo" => sub {

    my $app = builder {
        mount "/foo" => TestApp->to_app;
    };

    my $test = Plack::Test->create($app);

    my $res = $test->request( GET '/' );
    is $res->code, 404, "GET / not found";

    $res = $test->request( GET '/foo' );
    ok $res->is_success, "GET /foo successful";

    like $res->content, qr{<a href="/foo/old/href">some link},
      "link href changed from /old/href to /foo/old/href";

    like $res->content, qr{<img src="/foo/old/img"},
      "img src changed from /old/img to /foo/old/img";
};

done_testing;
