use strict;
use warnings;

use Test::More;

plan tests => 16;

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

        set plugins => {
            FlashNote => {
                queue   => 'key_single',
                dequeue => 'when_used',
            },
        };
    }

    use Dancer2::Plugin::FlashNote;

    get '/' => sub { template 'key_single', { where => 'root' } };

    get '/whine' => sub {
        flash( warn  => 'groan' );
        flash( error => 'GROAN' );
        template 'key_single', { where => 'whine' };
    };

    get '/noisy' => sub {
        flash( warn  => 'BOOM!' );
        flash( error => 'kaboom!' );
        flash( error => 'KABOOM!' );
        template 'key_single', { where => 'noisy' };
    };

    get '/fishy' => sub {
        flash( warn => 'SLIIIME!' );
        redirect '/';
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
like( $res->content, qr/root:\n   ''\n   ''\n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/whine';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /whine ] Request successful' );
like(
    $res->content,
    qr/whine:\n   'groan'\n   'GROAN'\n/,
    '[GET /whine ] Correct content'
);
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root:\n   ''\n   ''\n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/noisy';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /noisy] Request successful' );
like(
    $res->content,
    qr/noisy:\n   'BOOM!'\n   'KABOOM!'\n/,
    '[GET /noisy] Correct content'
);
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root:\n   ''\n   ''\n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

$req = GET '/fishy';
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
like(
    $res->content,
    qr/root:\n   'SLIIIME!'\n   ''\n/,
    '[GET / ] Root now has flash'
);
$jar->extract_cookies($res);

