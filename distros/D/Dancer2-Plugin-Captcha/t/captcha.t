use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Cookies;
use HTTP::Request::Common;

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Captcha;

    set session => 'Simple';
    set plugins => {
        Captcha => {
            new => {
                width => 160,
                height => 175,
                lines => 5,
                gd_font => 'giant',
            },
            create => [ 'normal', 'default' ],
            out => {
                force => 'png',
            },
            particle => [ 100 ],
        }
    };

    get '/get_captcha' => sub {
        generate_captcha;
    };

    get '/session' => sub {
        session('captcha')->{default}->{string};
    };

    get '/validate/:captcha' => sub {
        if ( is_valid_captcha(request->params->{captcha}) ) {
            remove_captcha;
            return "Good";
        }
        return "BAD";
    };
}

my $url = 'http://localhost';
my $jar  = HTTP::Cookies->new();
my $test = Plack::Test->create( TestApp->to_app );

my $string;

subtest 'Get captcha' => sub {
    my $req = GET "$url/get_captcha";

    $jar->add_cookie_header($req);

    my $res = $test->request( $req );

    ok $res->is_success, "get /get_captcha";

    like $res->content, qr/PNG/, "we received a PNG";

    $jar->extract_cookies($res);

};

subtest 'check session' => sub {
    my $req = GET "$url/session";

    $jar->add_cookie_header($req);

    my $res = $test->request( $req );

    ok $res->is_success, "get /session";

    $string = $res->content;

    like $string, qr/^\d+$/, "captcha string looks OK";
};

subtest 'wrong captcha' => sub {
    my $req = GET "$url/validate/bad";

    $jar->add_cookie_header($req);

    my $res = $test->request( $req );

    ok $res->is_success, "get /validate/bad";

    is $res->content, "BAD", "validation failed";
};

subtest 'correct captcha' => sub {
    my $req = GET "$url/validate/$string";

    $jar->add_cookie_header($req);

    my $res = $test->request( $req );

    ok $res->is_success, "get /validate/$string";

    is $res->content, "Good", "validation successful";
};

subtest 'retry captcha' => sub {
    my $req = GET "$url/validate/$string";

    $jar->add_cookie_header($req);

    my $res = $test->request( $req );

    ok $res->is_success, "get /validate/$string";

    is $res->content, "BAD", "validation failed";
};

done_testing;
