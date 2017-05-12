use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use DateTime;
use Digest::MD5 qw( md5_hex );
use JSON qw( encode_json decode_json );

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'test';
}

my $user = {
    uid       => '0123456',
    firstname => 'John',
    lastname  => 'Doe',
};

{

    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Auth::SAFE;

    get '/users' => require_login sub {
        my $user = logged_in_user;
        return encode_json($user);
    };
}

my $app = TestApp->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();

{
    my $res = $test->request( GET "$url/users" );
    ok( $res->is_redirect, 'Got redirect response' );
    $jar->extract_cookies($res);
    is(
        $res->header('Location'),
        TestApp->config->{plugins}{'Auth::SAFE'}{safe_url},
        'Redirect location is OK'
    );
}
{
    my $timestamp = DateTime->now->strftime('%Y:%m:%d:%H:%M:%S');
    my $digest =
      md5_hex( '0123456'
          . $timestamp
          . TestApp->config->{plugins}{'Auth::SAFE'}{shared_secret} );

    my $req = POST "$url/safe",
      [
        %$user,
        time   => $timestamp,
        digest => $digest,
      ];
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok( $res->is_success, 'POST /safe response is OK' );
    is_deeply( decode_json($res->content), $user, 'User authenticated' );
}
{
    my $req = GET "$url/users";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok( !$res->is_redirect, 'Got normal response' );
    is_deeply( decode_json($res->content), $user, 'User authenticated' );
}

done_testing;
