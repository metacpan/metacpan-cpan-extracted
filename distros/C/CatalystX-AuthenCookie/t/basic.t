use strict;
use warnings;

use Test::More tests => 18;

use lib 't/lib';

use Catalyst::Test 'TestApp';
use CGI::Util qw( unescape );
use Digest::SHA qw( sha512_base64 );
use HTTP::Cookies;
use HTTP::Date qw( str2time time2str );

{
    my $res = request('/login');

    my %cookies = cookies($res);

    is( scalar keys %cookies, 1, 'one cookie was set' );

    my $cookie = $cookies{'authen-cookie'};

    ok( $cookie, 'cookie name is authen-cookie' );
    is( $cookie->{path}, '/', 'cookie path is /' );
    ok( !$cookie->{secure},  'cookie path is not SSL-only' );
    ok( !$cookie->{expires}, 'cookie has no expiration set' );

    my $value = $cookie->{value};
    is( $value->{user_id}, 42, 'user_id in cookie is 42' );
    is(
        $value->{MAC}, sha512_base64( 'user_id', 42, 'the knife' ),
        'MAC is expected value'
    );

    is(
        get('/user_id'), 'none',
        'no user id without a cookie'
    );

    # Setting COOKIE in the ENV hash works for Cat 5.8, the extra parameter to
    # get works for 5.9+
    my $cookie_header = $res->header('Set-Cookie');
    $ENV{COOKIE} = $cookie_header;

    is(
        get( '/user_id', { extra_env => { 'COOKIE' => $cookie_header } } ),
        42,
        'user_id is 42 with cookie'
    );

    $cookie_header =~ s/MAC&./MAC&!/;
    $ENV{COOKIE} = $cookie_header;

    is(
        get( '/user_id', { extra_env => { 'COOKIE' => $cookie_header } } ),
        'none',
        'no user_id when cookie has bad MAC'
    );
}

{
    my $res = request('/long_login');

    my %cookies = cookies($res);
    my $cookie  = $cookies{'authen-cookie'};

    is(
        $cookie->{expires}, 'Tue, 03 Mar 2020 00:00:00 GMT',
        'cookie has explicit expiration in 2020'
    );
}

{
    my $res = request('/logout');

    # Unfortunately HTTP::Cookies will just ignore a cookie with no
    # value.
    my $cookie = $res->header('Set-Cookie');
    my ($expires) = $cookie =~ /expires=(.+)(?:;|\z)/;

    like(
        $cookie, qr/^authen-cookie=(.*);/,
        'value is explicitly empty'
    );
    cmp_ok(
        str2time($expires), '<', time,
        'cookie has explicit expiration in the past'
    );
}

{
    my $res = request('/logout');

    my %cookies = cookies($res);
    my $cookie  = $cookies{'authen-cookie'};

    ok(
        !keys %{ $cookie->{value} },
        'cookie value is empty'
    );
}

{
    TestApp->config()->{authen_cookie} = {
        mac_secret => 'the knife',
        name       => 'my-cookie',
        path       => '/path',
        secure     => 1,

        # Cannot just use any random thing, because it needs to
        # match the fake request associated with the response.
        domain => '.local',
    };
}

{
    my $res = request('/login');

    my %cookies = cookies($res);

    my $cookie = $cookies{'my-cookie'};

    ok( $cookie, 'cookie name is my-cookie' );
    is( $cookie->{path}, '/path', 'cookie path is /path' );
    ok( $cookie->{secure}, 'cookie path is SSL-only' );
    is( $cookie->{domain}, '.local', 'cookie domain is .local' );
}

sub cookies {
    my $res = shift;

    my $request = HTTP::Request->new( GET => 'http://localhost/' );
    $res->request($request);

    my $jar = HTTP::Cookies->new();
    $jar->extract_cookies($res);

    my %cookies;
    my $extract = sub {
        my (
            undef, $name, $val,    $path, $domain,
            undef, undef, $secure, $expires,
            undef, undef
        ) = @_;

        my %value = map { unescape($_) } split /&/, $val;

        $cookies{$name} = {
            value   => \%value,
            path    => $path,
            domain  => $domain,
            secure  => $secure,
            expires => ( $expires ? time2str($expires) : undef ),
        };
    };

    $jar->scan($extract);

    return %cookies;
}
