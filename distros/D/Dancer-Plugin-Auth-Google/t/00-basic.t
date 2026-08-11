use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 8;

{
    use Dancer;
    use Dancer::Plugin::Auth::Google;

    setting( plugins => {
        'Auth::Google' => {
            client_id        => 1234,
            client_secret    => 4321,
            callback_url     => 'http://myserver:3000/auth/google/callback',
            callback_success => '/ok',
            callback_fail    => '/not-ok',
            access_type      => 'offline',
            scope            => 'profile email whatever',
        },
    });

    ok auth_google_init(), 'able to load auth_google_init()';

    ok my $u = auth_google_authenticate_url(), 'auth_google_authenticate_url returns';
    isa_ok $u, 'URI';
    require URI;
    my $expected = URI->new('https://accounts.google.com/o/oauth2/v2/auth');
    $expected->query_form(
        client_id     => 1234,
        redirect_uri  => 'http://myserver:3000/auth/google/callback',
        scope         => 'profile email whatever',
        access_type   => 'offline',
        response_type => 'code',
    );
    ok $u->eq($expected), "$u looks like $expected";

    ok my $u2 = auth_google_authenticate_url( extra => 'moar data', and => 42 ), 'augmented authenticate url';
    isa_ok $u2, 'URI';
    $expected->query_form( $expected->query_form(), extra => 'moar data', and => 42 );
    ok $u2->eq($expected), "$u2 looks like $expected";
}

use Dancer::Test;

route_exists [ GET => '/auth/google/callback' ], 'google auth callback route exists';


