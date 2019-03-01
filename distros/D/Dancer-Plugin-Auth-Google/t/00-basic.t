use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 6;

{
    use Dancer;

    # settings must be loaded before we load the plugin
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

    eval 'use Dancer::Plugin::Auth::Google';
    die $@ if $@;
    ok 1, 'plugin loaded successfully';

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
}

use Dancer::Test;

route_exists [ GET => '/auth/google/callback' ], 'google auth callback route exists';


