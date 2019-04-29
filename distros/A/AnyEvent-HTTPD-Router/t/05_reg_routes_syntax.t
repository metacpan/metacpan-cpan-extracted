#!perl
use lib 't/lib';
use common::sense;

use Test::More;
use Test::Exception;

use AnyEvent::HTTPD::Router;
use MockedRequest;

sub make_route_param {
    my $method = shift;
    my $url    = shift;
    my $cb     = sub {
        my $httpd = shift;
        my $req   = shift;
        is $req->method, $method, 'method is correct';
        is $req->url->path, $url, 'url is correct';
    };
    return ([$method], $url, $cb);
}


my $httpd  = AnyEvent::HTTPD::Router->new();

throws_ok {
    $httpd->reg_routes(
        GET  => '/some/url'        => sub { },
        POST => '/some/thing/else' => sub { },
        'something that is wrong',
    );
} qr/confusing/, 'wrong number of parameters';

throws_ok {
    $httpd->reg_routes;
} qr/required/, 'reg_routes without parameter';

throws_ok {
    $httpd->reg_routes( undef,  '/url',  sub {} );
} qr/verbs or methods/, 'undefined method';

throws_ok {
    $httpd->reg_routes( 'strange method',  '/url',  sub {} );
} qr/verbs or methods/, 'unknown method';

throws_ok {
    $httpd->reg_routes( GET =>  undef,  sub {} );
} qr/path/, 'undefined path';

throws_ok {
    $httpd->reg_routes( GET =>  '/url',  undef );
} qr/callback/, 'undefined callback';

throws_ok {
    $httpd->reg_routes( GET =>  'path syntax',  sub {} );
} qr/path syntax/, 'invalid path syntax';

$httpd = AnyEvent::HTTPD::Router->new(known_methods => ['GET']);
throws_ok {
    $httpd->reg_routes(POST => '/foo' => sub { });
} qr/verbs or methods/, 'POST is no longer a known http method';

$httpd = AnyEvent::HTTPD::Router->new(known_methods => ['GET', 'COPY']);
lives_ok {
    $httpd->reg_routes(COPY => '/foo' => sub { });
} 'COPY is now an acceptable method';

done_testing;

