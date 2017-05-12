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
        my $epoch = timegm( 0, 0, 12, 10, 12 - 1, 2012 - 1900 );
        $epoch = timegm( 0, 0, 12, 28, 12 - 1, 2012 - 1900 ) if $fullmoon;
        return $epoch;
    }
};

use Plack::Middleware::Acme::Werewolf;

my $handler = builder {
    enable "Plack::Middleware::Acme::Werewolf",
        moonlength  => 4,
        message     => 'Werewolf!',
    ;
    sub {
        [ 200, ['Content-Type' => 'text/plain'], ['ok'] ];
    };
};

test_psgi
    app => $handler,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 200;
        is $res->content, 'ok';
        $fullmoon = 1;
        $res = $cb->(GET "http://localhost/");
        is $res->code, 403;
        is $res->content, 'Werewolf!';
    },
;

done_testing;

