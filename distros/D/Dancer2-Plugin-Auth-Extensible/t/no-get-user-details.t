use strict;
use warnings;

use Test::More;
use Test::Deep;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'no-get-user-details';
}

{

    package TestApp;
    use Test::More;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    my $plugin = app->with_plugin('Auth::Extensible');
    my $trap   = dancer_app->logger_engine->trapper;
    my $logs;

    get '/logged_in_user' => sub {
        my $user = logged_in_user;
        return join( ":", keys %$user );
    };
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $trap = TestApp->dancer_app->logger_engine->trapper;
my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();

{
    my $req = POST "$url/login", [ username => 'dave', password => 'beer' ];
    my $res = $test->request($req);
    $jar->extract_cookies($res);
    ok $res->is_redirect, "POST /login with good password response is_redirect";
    my $logs = $trap->read;
    cmp_deeply $logs, superbagof(
        {
            formatted => ignore(),
            level => 'debug',
            message => 'config1 accepted user dave'
        }
    );
}
{
    my $req = GET "$url/logged_in_user";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);
    ok $res->is_success, "GET /logged_in_user is_success";
    is $res->content, "username", "User hash has single key 'username'"
        or diag explain $res->content;
}

done_testing;
