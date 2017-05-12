use strict;
use warnings;

use Test::More;

plan tests => 6;

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

    get '/single' => sub {
        flash('whatever');
        template 'auto', { where => '/single' };
    };

    get '/multiple' => sub {
        flash(qw( whatever you do ));
        template 'auto', { where => '/multiple' };
    };

}

my $jar = HTTP::Cookies->new;
my $app = TestApp->to_app;
is( ref $app, 'CODE', 'Got app' );
my $test = Plack::Test->create($app);
my $req;
my $res;

$req = GET 'http://127.0.0.1/single';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /single ] Request successful' );
like( $res->content, qr/single: whatever\n/, '[GET /single ] Correct content' );
$jar->extract_cookies($res);

$req = GET 'http://127.0.0.1/multiple';
$jar->add_cookie_header($req);
$res = $test->request($req);
is( $res->code, 200, '[GET /multiple ] Request successful' );
like(
    $res->content,
    qr/multiple: whatever\*you\*do\n/,
    '[GET /multiple ] Correct content'
);
$jar->extract_cookies($res);
