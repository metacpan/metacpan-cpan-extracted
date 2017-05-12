use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'no-login-handler';
}

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    set logger => 'capture';
    set log    => 'debug';

    post '/login' => sub {
        my $username = body_parameters->get('username');
        my $password = body_parameters->get('password');
        my ( $success, $realm ) = authenticate_user( $username, $password );
        if ($success) {
            session logged_in_user       => $username;
            session logged_in_user_realm => $realm;
            return "Welcome!";
        }
        else {
            return "Not allowed";
        }
    };

    any '/logout' => sub {
        app->destroy_session;
    };

    get '/loggedin' => require_login sub {
        "You are logged in";
    };

}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $trap = TestApp->dancer_app->logger_engine->trapper;
my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();

{
    my $res = $test->request( GET "$url/loggedin" );
    $jar->extract_cookies($res);
    ok $res->is_redirect,
      "Trying a protected page when not logged in causes redirect";
}
{
    my $req = POST "$url/login", [ username => 'dave', password => 'bad' ];
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok $res->is_success, "POST /login with bad password response is OK";
    is $res->content, "Not allowed", "... and we see our custom response.";
}
{
    my $req = GET "$url/loggedin";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok $res->is_redirect, "... and we still cannot reach protected page.";
}
{
    my $req = POST "$url/login", [ username => 'dave', password => 'beer' ];
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok $res->is_success, "POST /login with good password response is OK";
    is $res->content, "Welcome!", "... and we see our custom response";
}
{
    my $req = GET "$url/loggedin";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok $res->is_success, "... and we can reach protected page";
    is $res->content,    "You are logged in",
      "... which has the content we expect.";
}
{
    my $req = GET "$url/logout";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok $res->is_success, "/logout is successful";
}
{
    my $req = GET "$url/loggedin";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok $res->is_redirect, "... and we can no longer reach protected page.";
}

done_testing;
