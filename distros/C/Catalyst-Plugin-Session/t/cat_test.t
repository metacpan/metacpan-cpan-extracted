use strict;
use warnings;

use Test::Needs qw(
  Catalyst::Plugin::Session::State::Cookie
  Catalyst::Plugin::Authentication
);

use Test::More;

use HTTP::Request::Common;

use lib "t/lib";

use Catalyst::Test 'SessionTestApp';
my $res;

$res = request(POST 'http://localhost/login', [username => 'bob', password => 's00p3r', remember => 1]);
is($res->code, 200, 'succeeded');
my $cookie = $res->header('Set-Cookie');
ok($cookie, 'Have a cookie');

# cookie is changed by the get
sleep(1);
$res = request(GET 'http://localhost/page', Cookie => $cookie);
like($res->content, qr/logged in/, 'logged in');
my $new_cookie = $res->header('Set-Cookie');
isnt( $cookie, $new_cookie, 'cookie expires has been updated' );

# request with no cookie
$res = request(GET 'http://localhost/page' );
like($res->content, qr/please login/, 'not logged in');
$new_cookie = $res->header('Set-Cookie');
ok( ! defined $new_cookie, 'no cookie created' );

# check that cookie is reset by reset_session_expires
$res = request(GET 'http://localhost/reset_session_expires', Cookie => $cookie);
my $reset_cookie = $res->header('Set-Cookie');
isnt( $cookie, $reset_cookie, 'Cookie has been changed by reset_session' );

# this checks that cookie exists after a logout and redirect
# Catalyst::Plugin::Authentication removes the user session (remove_persisted_user)
$res = request(GET 'http://localhost/logout_redirect', Cookie => $cookie);
is($res->code, 302, 'redirected');
is($res->header('Location'), 'http://localhost/from_logout_redirect', 'Redirected after logout_redirect');
ok($res->header('Set-Cookie'), 'Cookie is there after redirect');

done_testing;
