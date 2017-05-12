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
    $ENV{DANCER_ENVIRONMENT} = 'login-without-redirect';
    $ENV{DANCER_VIEWS}       = 't/lib/views/login-without-redirect';
}

{
    package TestApp;
    use lib 't/lib';
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    set logger => 'capture';
    set log    => 'debug';

    get '/use_custom_login_template' => sub {
        my $plugin = app->with_plugin('Auth::Extensible');
        $plugin->{login_template} = 'custom_login';
    };
    get '/use_builtin_login_template' => sub {
        my $plugin = app->with_plugin('Auth::Extensible');
        $plugin->{login_template} = 'login';
    };
    get '/loggedin' => require_login sub {
        "You are logged in";
    };
    post '/protected_post' => require_login sub {
        my $params = params;
        send_as YAML => [ "You are logged in", $params ];
    };
    get '/beer' => require_role BeerDrinker => sub {
        "Have some beer";
    };
    get '/cider' => require_role CiderDrinker => sub {
        "Have some cider";
    };
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $trap = TestApp->dancer_app->logger_engine->trapper;
my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();

{
    # WWW-Authenticate robot header

    my $req = GET "$url/loggedin";
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 401,
      "Trying a require_login page with *no* User-Agent header gets 401";
    like $res->header('www-authenticate'), qr/Basic realm=/,
      "... and we have a WWW-Authenticate header with Basic realm";
    like $res->content, qr/You need to log in to continue/,
      "... and we can see a login form";
    like $res->content, qr/input.+name="__auth_extensible_username/,
      "... and we see __auth_extensible_username field";
    like $res->content, qr/This text is in the layout/,
      "... and the response is wrapped in the layout.";
}
{
    # WWW-Authenticate real user (non-robot) header

    my $req = GET "$url/loggedin",
        'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.1 (KHTML like Gecko) Chrome/21.0.1180.83 Safari/537.1';
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 401,
      "Trying a require_login page with real User-Agent header gets 401";
    like $res->header('www-authenticate'), qr/FormBased.+use form to log in/,
      "... and we have a WWW-Authenticate header which says use the form";
    like $res->content, qr/You need to log in to continue/,
      "... and we can see a login form";
    like $res->content, qr/input.+name="__auth_extensible_username/,
      "... and we see __auth_extensible_username field";
    like $res->content, qr/This text is in the layout/,
      "... and the response is wrapped in the layout.";

}
{
    # cutom login_template

    $test->request(GET '/use_custom_login_template');

    my $req = GET "$url/loggedin";
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 401,
      "Trying a require_login page with custom login_template gets 401";
    like $res->header('www-authenticate'), qr/Basic realm=/,
      "... and we have a WWW-Authenticate header with Basic realm";
    like $res->content, qr/Custom Login Page/,
      "... and we can see our custom login form";
    like $res->content, qr/input.+name="__auth_extensible_username/,
      "... and we see __auth_extensible_username field";
    like $res->content, qr/This text is in the layout/,
      "... and the response is wrapped in the layout.";

    $test->request(GET '/use_builtin_login_template');

}
{
    # bad login

    $trap->read;
    my $req =
      POST "$url/loggedin",
      [
        __auth_extensible_username => 'dave',
        __auth_extensible_password => 'cider',
      ];
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 401,
      "Try posting bad login details to a require_login page gets 401 response"
          or diag explain $trap->read;
    like $res->content, qr/You need to log in to continue/,
      "... and we can see a login form";
    like $res->content, qr/LOGIN FAILED/,
      "... and we see LOGIN FAILED";
    like $res->content, qr/input.+name="__auth_extensible_username/,
      "... and we see __auth_extensible_username field";
    like $res->content, qr/This text is in the layout/,
      "... and the response is wrapped in the layout.";
}
{
    # good login

    $trap->read;
    my $req =
      POST "$url/loggedin",
      [
        __auth_extensible_username => 'dave',
        __auth_extensible_password => 'beer',
      ];
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    ok $res->is_success,
      "Try posting real login details to a require_login page is_success"
          or diag explain $trap->read;
    is $res->content, "You are logged in",
      "... and we see the real page content." or diag explain $trap->read;

    # logout
    $req = GET '/logout';
    $jar->add_cookie_header($req);
    $res = $test->request( $req );
    $jar->extract_cookies($res);
}
{
    my $req = GET "$url/beer";
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 401,
      "Trying a require_role page gets 401 response";
    like $res->header('www-authenticate'), qr/Basic realm=/,
      "... and we have a WWW-Authenticate header with Basic realm";
    like $res->content, qr/You need to log in to continue/,
      "... and we can see a login form";
    like $res->content, qr/input.+name="__auth_extensible_username/,
      "... and we see __auth_extensible_username field.";

}
{
    # try login to /beer with bad password

    my $req =
      POST "$url/beer",
      [
        __auth_extensible_username => 'dave',
        __auth_extensible_password => 'cider',
      ];
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 401,
      "Trying POST to require_role with bad password gets 401 response";
    like $res->header('www-authenticate'), qr/Basic realm=/,
      "... and we have a WWW-Authenticate header with Basic realm";
    like $res->content, qr/You need to log in to continue/,
      "... and we can see a login form";
    like $res->content, qr/input.+name="__auth_extensible_username/,
      "... and we see __auth_extensible_username field";
    like $res->content, qr/This text is in the layout/,
      "... and the response is wrapped in the layout.";
}
{
    # try login to /beer with good password

    my $req =
      POST "$url/beer",
      [
        __auth_extensible_username => 'dave',
        __auth_extensible_password => 'beer',
      ];
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    ok $res->is_success,
      "Trying POST to require_role beer with good password is_success";
    is $res->content, "Have some beer",
      "... and we got \"Have some beer\".";
}
{
    my $req = GET "$url/beer";
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    ok $res->is_success,
      "Trying GET to require_role beer is_success";
    is $res->content, "Have some beer",
      "... and we got \"Have some beer\".";
}
{
    my $req = GET "$url/cider";
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 403,
      "Trying GET to require_role cider returns reponse code 403";
    like $res->content, qr/Permission Denied/,
      "... and we got the permission denied page";
    like $res->content, qr/This text is in the layout/,
      "... wrapped in the layout.";
}
{
    my $req = GET "$url/loggedin";
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    ok $res->is_success,
      "Trying GET to require_login page is_success";
    is $res->content, "You are logged in",
      "... and we got \"You are logged in\".";

    # logout
    $req = GET '/logout';
    $jar->add_cookie_header($req);
    $res = $test->request( $req );
    $jar->extract_cookies($res);
}
{
    # post route with params

    my $req = POST "$url/protected_post",
      [ one => 'two', three => ['four','five'] ];
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 401,
      "Trying a require_login POST route gets 401";
    like $res->header('www-authenticate'), qr/Basic realm=/,
      "... and we have a WWW-Authenticate header with Basic realm";
    like $res->content, qr/You need to log in to continue/,
      "... and we can see a login form";
    like $res->content, qr/input.+name="__auth_extensible_username/,
      "... and we see __auth_extensible_username field";
    like $res->content, qr/This text is in the layout/,
      "... and the response is wrapped in the layout.";
}
{
    # bad password

    $trap->read;
    my $req =
      POST "$url/protected_post",
      [
        __auth_extensible_username => 'dave',
        __auth_extensible_password => 'cider',
      ];
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    is $res->code, 401,
      "Now we post a bad password to the transparent login route and get 401";
    like $res->header('www-authenticate'), qr/Basic realm=/,
      "... and we have a WWW-Authenticate header with Basic realm";
    like $res->content, qr/You need to log in to continue/,
      "... and we can see a login form";
    like $res->content, qr/input.+name="__auth_extensible_username/,
      "... and we see __auth_extensible_username field";
    like $res->content, qr/This text is in the layout/,
      "... and the response is wrapped in the layout.";
}
{
    # good password and we should get stashed params back

    $trap->read;
    my $req =
      POST "$url/protected_post",
      [
        __auth_extensible_username => 'dave',
        __auth_extensible_password => 'beer',
      ];
    $jar->add_cookie_header($req);
    my $res = $test->request( $req );
    $jar->extract_cookies($res);

    ok $res->is_success,
      "Trying POST to require_role beer with good password is_success"
      or diag explain $trap->read;

    my $data = YAML::Load( $res->content ) or diag $res->content;
    cmp_deeply $data,
      [
        'You are logged in',
        {
            __auth_extensible_password => 'beer',
            __auth_extensible_username => 'dave',
            one                        => 'two',
            three                      => [ 'four', 'five' ]
        }
      ],
      "... and stashed params look good."
      or diag explain $data;
}

done_testing;
