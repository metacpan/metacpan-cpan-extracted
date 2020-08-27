use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;

use HTTP::Cookies;
use Catalyst::Utils ();

use Catalyst::Test qw(CookieTestApp);

my $jar = HTTP::Cookies->new;
my %cookie;
my $get = sub {
    my $url = shift;
    my $req = Catalyst::Utils::request($url);
    $jar->add_cookie_header($req);
    my $res = request($req);
    $jar->extract_cookies($res);

    $jar->scan( sub {
        if ($_[1] eq 'cookietestapp_session') {
            @cookie{qw(
                version
                key
                val
                path
                domain
                port
                path_spec
                secure
                expires
                discard
                hash
            )} = @_;
        }
    } );

    return $res;
};

my $res;

$res = $get->('/stream');
ok $res->is_success, 'get page';
like $res->content, qr/hit number 1/, 'session data created';

my $expired = $cookie{expires};

$res = $get->('/page');
ok $res->is_success, 'get page';
like $res->content, qr/hit number 2/, 'session data restored';

$res = $get->('/page');
ok $res->is_success, 'get page';
like $res->content, qr/hit number 3/, 'session data restored';

sleep 1;

$res = $get->('/page');
ok $res->is_success, 'get page';
like $res->content, qr/hit number 4/, 'session data restored';

cmp_ok $expired, '<', $cookie{expires}, 'cookie expiration was extended';
$expired = $cookie{expires};

$res = $get->('/page');
ok $res->is_success, 'get page';
like $res->content, qr/hit number 5/, 'session data restored';

sleep 1;

$res = $get->('/stream');
ok $res->is_success, 'get stream';
like $res->content, qr/hit number 6/, 'session data restored';

cmp_ok $expired, '<', $cookie{expires}, 'streaming also extends cookie';

$res = $get->('/deleteme');
ok $res->is_success, 'get page';
is $res->content, '1', 'session id changed';

$res = $get->('https://localhost/page');
ok $res->is_success, 'get page over HTTPS - init session';
like $res->content, qr/hit number 1/, 'first hit';

$res = $get->('http://localhost/page');
ok $res->is_success, 'get page again over HTTP';
like $res->content, qr/hit number 1/, 'first hit again - cookie not sent';

$res = $get->('https://localhost/page');
ok $res->is_success, 'get page over HTTPS';
like $res->content, qr/hit number 2/, 'second hit';

done_testing;
