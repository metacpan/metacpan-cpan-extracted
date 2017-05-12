use strict;
use warnings;

use Test::More;

plan tests => 10;

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
                queue   => 'key_single',
                dequeue => 'by_key',
            },
        };
    }

    use Dancer2::Plugin::FlashNote;

    get '/' => sub {
        template 'key_single', { where => 'root' };
    };

    get '/whine' => sub {
        flash( warn  => 'groan' );
        flash( error => 'GROAN' );
        template 'key_warn', { where => 'whine' };
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
like(
    $res->content,
    qr/root:\n   ''\n   ''\n/,
    '[GET / ] response for / has no flash message'
);
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/whine';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /whine ] Request successful' );
like(
    $res->content,
    qr/whine:\n\* warn: 'groan'\n/,
    '[GET /whine ] Correct content'
);
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like(
    $res->content,
    qr/root:\n   ''\n   'GROAN'\n/,
    '[GET / ] response for / collects unused keys'
);
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET / ] Request successful' );
like(
    $res->content,
    qr/root:\n   ''\n   ''\n/,
    '[GET / ] response for / is now empty'
);
$jar->extract_cookies($res);
