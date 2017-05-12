use strict;
use warnings;

use Test::More;
use Test::Deep;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use YAML;

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'base';
    $ENV{DANCER_VIEWS}       = 't/lib/views/';
}

{

    package TestApp;
    use lib 't/lib';
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;
    use Dancer2::Plugin::Auth::Extensible::Rights;

    set logger => 'capture';
    set log    => 'debug';

    get '/createitem' => require_right createitem => sub { return 1 };
    get '/deleteitem' => require_right deleteitem => sub { return 1 };
    get '/deleteall'  => require_right deleteall  => sub { return 1 };

}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $trap = TestApp->dancer_app->logger_engine->trapper;
my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();

{
    # bad login

    $trap->read;
    my $req = POST "$url/login",
        [
        username => 'dave',
        password => 'beer',
        ];
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);

    ok $res->content =~ m/LOGIN FAILED/, "login with bad credentials get catched"
}
{
    # good login

    $trap->read;
    my $req = POST "$url/login",
        [
        username => 'dave',
        password => 'supersecret',
        ];
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);

    is $res->code, 302, "Try posting real login details to a require_login page is_success"
        or diag explain $trap->read;

    # logout
    $req = GET '/logout';
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
}
{
    # rights tests for dave

    $trap->read;
    my $req = POST "$url/login",
        [
        username => 'dave',
        password => 'supersecret',
        ];
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);

    is $res->code, 302, "logging in as dave"
        or diag explain $trap->read;

    $req = GET "$url/createitem";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
    is $res->content, 1, "createitem is allowed"
        or diag explain $trap->read;

    $req = GET "$url/deleteitem";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
    is $res->content, 1, "deleteitem is allowed"
        or diag explain $trap->read;

    $req = GET "$url/deleteall";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
    is $res->content, 1, "deleteall is allowed"
        or diag explain $trap->read;

    # logout
    $req = GET '/logout';
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
}
{
    # rights tests for bob

    $trap->read;
    my $req = POST "$url/login",
        [
        username => 'bob',
        password => 'alsosecret',
        ];
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);

    is $res->code, 302, "logging in as bob"
        or diag explain $trap->read;

    $req = GET "$url/createitem";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
    is $res->content, 1, "createitem is allowed"
        or diag explain $trap->read;

    $req = GET "$url/deleteitem";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
    is $res->code, 403, "deleteitem is not allowed"
        or diag explain $trap->read;

    $req = GET "$url/deleteall";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
    is $res->code, 403, "deleteall is not allowed"
        or diag explain $trap->read;

    # logout
    $req = GET '/logout';
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);
}

done_testing;
