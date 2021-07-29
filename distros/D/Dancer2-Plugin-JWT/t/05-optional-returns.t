#!/perl -T
use strict;
use warnings;

use Test::More import => ['!pass'];
use Test::WWW::Mechanize::PSGI;
use Crypt::JWT qw(encode_jwt decode_jwt);
use HTTP::Status qw( :constants );

{
    use Dancer2;
    BEGIN {
        set plugins => {
            JWT => {
                secret => 'test-secret',
                set_authorization_header => 0,
                expose_authorization_header => 0,
                set_cookie_header => 0,
                set_location_header => 1,
            }
        };
    }
    use Dancer2::Plugin::JWT;

    set log => 'debug';

    get '/defined/jwt' => sub {
        defined(jwt) ? 'DEFINED' : 'UNDEFINED';
    };

    get '/define/jwt' => sub {
        jwt { my => 'data' };
        'OK';
    };

    get '/redirect/jwt' => sub {
        jwt { my => 'redirect' };
        redirect q{/};
    };

    get q{/} => sub {
        'Plain OK';
    };
}

my $app = __PACKAGE__->to_app;
is (ref $app, 'CODE', 'Got the test app');

my $mech =  Test::WWW::Mechanize::PSGI -> new ( app => $app );

my $secret = 'test-secret';
my $alg = 'PBES2-HS256+A128KW';
my $enc = 'A128CBC-HS256';
my $need_iat = 1;
my $need_nbf = 1;
my $need_exp = 2;
my %jwt_claims = ( 'some' => 1, 'jwt' => 2, 'stuff' => 3 );
my $jwt = encode_jwt(
    payload      => \%jwt_claims,
    key          => $secret,
    alg          => $alg,
    enc          => $enc,
    auto_iat     => $need_iat,
    relative_exp => $need_exp,
    relative_nbf => $need_nbf,
);

subtest 'define' => sub {
    $mech->get_ok('/defined/jwt');
    $mech->content_is('UNDEFINED', 'by default it is undef');

    $mech->lacks_header_ok('Authorization', 'No Authorization header');
    $mech->lacks_header_ok('Access-Control-Expose-Headers', 'No Access-Control-Expose-Headers header');
    $mech->lacks_header_ok('Set-Cookie', 'No Set-Cookie header');
    $mech->lacks_header_ok('Location', 'No Location header');

    done_testing();
};

subtest 'define' => sub {
    $mech->add_header('Authorization' => $jwt);
    $mech->get_ok('/define/jwt');

    $mech->content_is('OK', 'No exceptions on defining jwt');
    $mech->lacks_header_ok('Authorization', 'No Authorization header');
    $mech->lacks_header_ok('Set-Cookie', 'No Set-Cookie header');
    $mech->lacks_header_ok('Location', 'No Location header, this is not redirect');

    done_testing();
};

subtest 'redirect' => sub {
    # Disable redirection. Otherwise $mech would simply continue with another
    # request and we would not see the Location header in that other response.
    $mech->requests_redirectable( [] );
    $mech->add_header('Authorization' => $jwt);
    my $resp = $mech->get('/redirect/jwt'); # Return HTTP::Response

    is($resp->code, HTTP_FOUND, 'Response is redirection');
    is($resp->header('Authorization'), undef, 'No Authorization header');
    is($resp->header('Set-Cookie'), undef, 'No Set-Cookie header');
    ok($resp->header('Location'), 'Have Location header, this is redirect');

    done_testing();
};

done_testing();
