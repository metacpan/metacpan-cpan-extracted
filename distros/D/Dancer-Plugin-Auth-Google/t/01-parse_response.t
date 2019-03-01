use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 10;

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

    my ($data, $error) = Dancer::Plugin::Auth::Google::_parse_response(
        '{"foo": 42}'
    );
    is_deeply( $data, { foo => 42 }, 'able to parse valid JSON response' );
    is $error, undef, 'no error parsing valid JSON response';

    ($data, $error) = Dancer::Plugin::Auth::Google::_parse_response(
        'some random invalid data'
    );
    is $data, undef, 'no data parsing invalid JSON';
    like $error, qr/error parsing JSON/, 'error message for invalid data';

    ($data, $error) = Dancer::Plugin::Auth::Google::_parse_response(
        'some random invalid data with timeout somewhere'
    );
    is $data, undef, 'no data parsing invalid JSON';
    like $error, qr/google auth: timeout/, 'error message for timeout';

    ($data, $error) = Dancer::Plugin::Auth::Google::_parse_response(
        '{"bar": "baz"}'
    );
    is_deeply( $data, { bar => 'baz' }, 'able to parse valid JSON response (second attempt)' );
    is $error, undef, 'no error parsing valid JSON response (second attempt)';
}
