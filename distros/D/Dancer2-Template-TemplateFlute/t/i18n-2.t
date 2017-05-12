use strict;
use warnings;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'i18n-2';
}

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

{

    package TestApp;
    use Dancer2;
    use lib 't/lib';
    use MyTestApp::Lexicon2;

    get '/:lang/try' => sub {
        var lang => param('lang');
        template 'i18n';
    };

    get '/:lang/:foo' => sub {
        var lang => param('lang');
        my $loc =
          MyTestApp::Lexicon2->new( prepend => 'X = ', append => ' = Z' );
        return $loc->try_to_translate(param 'foo');
    };
}

my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();
my $test = Plack::Test->create( TestApp->to_app );
my $trap = TestApp->dancer_app->logger_engine->trapper;

my $res = $test->request( GET '/en/try' );
ok $res->is_success, "GET '/en/try' successful" or diag explain $trap->read;
$jar->extract_cookies($res);
like $res->content, qr/X I am english now Z/, "got: X I am english now Z";

my $req = GET '/en/blabla';
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET '/en/blabla' successful" or diag explain $trap->read;
ok $res->content eq 'blabla', "got: blabla";

$req = GET '/it/try';
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET '/it/try' successful" or diag explain $trap->read;
like $res->content, qr/X Sono in italiano Z/, "got: X Sono in italiano  Z";

$req = GET '/it/blabla';
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "GET '/it/blabla' successful" or diag explain $trap->read;
ok $res->content eq 'blabla', "got: blabla";

done_testing;
