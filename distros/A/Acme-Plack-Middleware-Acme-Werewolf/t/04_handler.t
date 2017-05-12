use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use HTTP::Response;
use Time::Local qw(timegm);

my $fullmoon = 0;

BEGIN {
    *CORE::GLOBAL::time = sub {
        return timegm( 0, 0, 12, 28, 12 - 1, 2012 - 1900 );
    }
};

use Plack::Middleware::Acme::Werewolf;

my $handler = builder {
    enable "Plack::Middleware::Acme::Werewolf",
        moonlength => 4,
        handler => sub {
            my ( $c, $env, $moonage ) = @_;
            like $moonage, qr/^14/;
            isa_ok $c, 'Plack::Middleware::Acme::Werewolf';
            is ref($env), 'HASH';
            return [ 403, ['Content-Type' => 'text/plain'], ['Werewolf!'] ];
        },
    ;
    sub {
        [ 200, ['Content-Type' => 'text/plain'], ['ok'] ];
    };
};

test_psgi $handler, sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 403;
        is $res->content, 'Werewolf!';
};

done_testing;

