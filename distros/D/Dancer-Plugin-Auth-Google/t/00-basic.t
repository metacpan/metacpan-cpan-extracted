use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 4;

{
    use Dancer;

    # settings must be laoded before we load the plugin
    setting( plugins => {
        'Auth::Google' => {
            client_id        => 1234,
            client_secret    => 4321,
            callback_url     => 'http://myserver:3000/auth/google/callback',
            callback_success => '/ok',
            callback_fail    => '/not-ok',
            scope            => 'plus.login',
        },
    });

    eval 'use Dancer::Plugin::Auth::Google';
    die $@ if $@;
    ok 1, 'plugin loaded successfully';

    ok auth_google_init(), 'able to load auth_google_init()';

    is auth_google_authenticate_url(),
       'https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=1234&redirect_uri=http%3A%2F%2Fmyserver%3A3000%2Fauth%2Fgoogle%2Fcallback&scope=plus.login&access_type=online',
       'auth_google_authenticate_url() returns the proper facebook_auth_url';
}

use Dancer::Test;

route_exists [ GET => '/auth/google/callback' ], 'google auth callback route exists';


