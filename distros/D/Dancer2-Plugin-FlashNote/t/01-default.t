use strict;
use warnings;

use Test::More;

plan tests => 14;

use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

use_ok 'Dancer2::Plugin::FlashNote';

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::FlashNote;

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

        #setting show_errors => 1,
        #setting log => "core",
    }

    get '/' => sub { template 'multiple', { where => 'root' } };

    get '/whine' => sub {
        flash('groan');
        template 'multiple', { where => 'whine' };
    };

    get '/noisy' => sub {
        flash('BOOM!');
        flash('KABOOM!');
        template 'multiple', { where => 'noisy' };
    };

    get '/fishy' => sub {
        flash('SLIIIME!');
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
like( $res->content, qr/root:\n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/whine';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /whine ] Request successful' );
like( $res->content, qr/whine:\n   groan\n\n/,
    '[GET /whine ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/noisy';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /noisy] Request successful' );
like(
    $res->content,
    qr/noisy:\n   BOOM!\n\n   KABOOM!\n\n/,
    '[GET /noisy] Correct content'
);
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like( $res->content, qr/root:\n/, '[GET / ] Correct content' );
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
like( $res->content, qr/root:\n   SLIIIME!\n\n/,
    '[GET / ] Root now has flash' );
$jar->extract_cookies($res);

