use strict;
use warnings;

use Test::More;

plan tests => 24;

use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

use_ok 'Dancer2::Plugin::FlashNote';

{

    package TestApp;
    use Dancer2;

    BEGIN {

        set engines => {
            template => {
                template_toolkit => {
                    start_tag => '<%',
                    end_tag   => '%>',

                },
            },
        };

        setting views => path( 't', 'views' );
        setting template => 'template_toolkit';
        set plugins      => {
            FlashNote => {
                queue   => 'single',
                dequeue => 'never',
            },
        };
    }

    use Dancer2::Plugin::FlashNote;

    get '/' => sub {
        template 'single', { where => 'root' };
    };

    get '/whine' => sub {
        flash('groan');
        template 'single', { where => 'whine' };
    };

    get '/noisy' => sub {
        flash('BOOM!');
        flash('KABOOM!');
        template 'single', { where => 'noisy' };
    };

    get '/fishy' => sub {
        flash('SLIIIME!');
        redirect uri_for '/';
    };

    get '/flush' => sub {
        flash_flush();
        redirect uri_for '/';
    };

}

my $jar = HTTP::Cookies->new;
my $app = TestApp->to_app;
is( ref $app, 'CODE', 'Got app' );
my $test = Plack::Test->create($app);
my $req;
my $res;

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root: \n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/whine';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /whine ] Request successful' );
like( $res->content, qr/whine: groan\n/, '[GET /whine ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root: groan\n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/noisy';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /noisy] Request successful' );
like( $res->content, qr/noisy: KABOOM!\n/, '[GET /noisy] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root: KABOOM!\n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/flush';
$jar->add_cookie_header($req);
$res = $test->request($req);
ok( $res->is_redirect, '[GET /flush] Redirect successful' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root: \n/, '[GET / ] Flash flushed correctly' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/fishy';
$jar->add_cookie_header($req);
$res = $test->request($req);
ok( $res->is_redirect, '[GET /fishy] Redirect successful' );
my $loc = $res->header('Location');
like( $loc, qr/\/$/, '[GET /fishy ] Redirect goes to /' );
$jar->extract_cookies($res);

$req = GET $loc;
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root: SLIIIME!\n/, '[GET / ] Root now has flash' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root: SLIIIME!\n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/flush';
$jar->add_cookie_header($req);
$res = $test->request($req);
ok( $res->is_redirect, '[GET /flush] Redirect successful' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root: \n/, '[GET / ] Flash flushed correctly' );
$jar->extract_cookies($res);

