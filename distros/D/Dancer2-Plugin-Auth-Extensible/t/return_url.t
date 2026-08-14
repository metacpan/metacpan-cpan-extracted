use strict;
use warnings;

use Test::More tests => 15;
use Plack::App::URLMap;
use Plack::Test;
use HTTP::Request::Common;
# Need to use URI not URI::URL as URI does not decode the URL parameters
# (needed to test for correct redirects)
use URI;
use URI::QueryParam;
use HTTP::Cookies;

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'provider-config'; #'return_url';
}

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    get '/restricted' => require_login sub {
        return "Welcome!";
    };
}

# Test double-insertion of mount point (see GH81)
{
    my $app = Plack::App::URLMap->new;
    $app->mount("/mypath" => TestApp->to_app);
    my $test = Plack::Test->create($app);

    my $res = $test->request(GET '/mypath/restricted');
    ok($res->code == 302, "Checking response code redirect (302)");

    my $uri = URI->new($res->header('Location'));

    my $jar  = HTTP::Cookies->new();
    my $req = POST $uri, [ username => 'dave', password => 'beer' ];
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);

    my $n_req = GET $res->header('Location');
    $jar->add_cookie_header($n_req);
    ok($n_req->url !~ m#/mypath/mypath/#, "Checking duplicate mount path");
    $res = $test->request($n_req);
    ok($res->code == 200, "Checking response code correct (not 404)");

    ok $res->is_success, "POST /login with good password response is OK";
    is $res->content, "Welcome!", "... and we see our custom response";
}

# Test simple return_url
{
    my $app = Dancer2->runner->psgi_app;
    my $test = Plack::Test->create($app);

    my $res = $test->request(GET '/restricted');
    ok($res->code == 302, "Checking response code redirect (302)");

    my $uri = URI->new($res->header('Location'));

    my $req = POST $uri, [ username => 'dave', password => 'beer' ];
    $res = $test->request($req);

    is($res->header('Location'), 'http://localhost/restricted', "Correct redirect for simple return_url");
}

# Test encoding and decoding of return_url
{
    my $app = Dancer2->runner->psgi_app;
    my $test = Plack::Test->create($app);

    my $res = $test->request(GET '/restricted?param1=foobar');
    ok($res->code == 302, "Checking response code redirect (302)");

    my $uri = URI->new($res->header('Location'));

    my $req = POST $uri, [ username => 'dave', password => 'beer' ];
    $res = $test->request($req);

    my $uri2 = URI->new($res->header('Location'));
    is($uri2->path, '/restricted', "Path of redirect is correct");
    is($uri2->query_param, 1, "Correct number of query parameters");
    is($uri2->query_param("param1"), "foobar", "Correct number of query parameters");
}

# Test for redirect to external URL (should not be possible for security reasons)
{
    my $app = Dancer2->runner->psgi_app;
    my $test = Plack::Test->create($app);

    my $res = $test->request(GET '/restricted');
    ok($res->code == 302, "Checking response code redirect (302)");

    my $uri = URI->new($res->header('Location'));

    my $jar  = HTTP::Cookies->new();
    my $req = POST $uri, [ username => 'dave', password => 'beer' ];
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    $jar->extract_cookies($res);

    $req = GET 'http://localhost/restricted';
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    is($res->code, 200, "Check logged in okay");

    $req = GET 'http://localhost/login?return_url=https://metacpan.org/';
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    ok($res->code == 302, "Checking response code correct (not 404)");
    $uri = URI->new($res->header('Location'));
    is($uri->host, "localhost", "Checking same hostname on redirect");
}

