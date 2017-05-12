use strict;
use warnings;

use Test::More;

plan tests => 4;

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
                queue     => 'single',
                arguments => 'array',
            },
        };
    }

    use Dancer2::Plugin::FlashNote;

    get '/' => sub {
        flash(qw( whatever you do ));
        template 'array', { where => 'root' };
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
like( $res->content, qr/root: whatever\*you\*do\n/,
    '[GET / ] Correct content' );
$jar->extract_cookies($res);
