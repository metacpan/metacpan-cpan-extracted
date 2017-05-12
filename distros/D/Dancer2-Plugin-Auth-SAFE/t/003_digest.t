use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use DateTime;
use Digest::MD5 qw( md5_hex );

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'test';
}

{

    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Auth::SAFE;

    get '/users' => require_login sub {
        my $user = logged_in_user;
        return "Hi there, $user->{firstname}";
    };
}

my $app = TestApp->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $url  = 'http://localhost';

{
    my $req = POST "$url/safe",
      [
        uid       => '0123456',
        firstname => 'John',
        lastname  => 'Doe',
        time      => '2016:11:26:17:48:40',
        digest    => '1',
      ];
    my $res = $test->request($req);
    is( $res->code, 401, 'Wrong digest' );
}
{
    my $dt_past = DateTime->now->subtract( minutes => 6 );
    my $timestamp = $dt_past->strftime('%Y:%m:%d:%H:%M:%S');
    my $digest =
      md5_hex( '0123456'
          . $timestamp
          . TestApp->config->{plugins}{'Auth::SAFE'}{shared_secret} );

    my $req = POST "$url/safe",
      [
        uid       => '0123456',
        firstname => 'John',
        lastname  => 'Doe',
        time      => $timestamp,
        digest    => $digest,
      ];
    my $res = $test->request($req);
    is( $res->code, 401, 'Old timestamp' );
}

done_testing;
