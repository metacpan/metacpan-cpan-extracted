use strict;
use warnings;

use Test::More;

plan tests => 8;

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
                queue   => 'single',
                dequeue => 'when_used',
            },
        };
    }

    use Dancer2::Plugin::FlashNote;

    get '/' => sub { template 'single', { where => 'root' } };

    get '/whine' => sub {
        flash('groan');
        template 'single', { where => 'whine' };
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
like( $res->content, qr/root: \n/, '[GET / ] Correct content' );
$jar->extract_cookies($res);

