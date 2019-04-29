#!perl
use lib 't/lib';
use common::sense;

use Test::More;
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


my $httpd  = 'not needed here';
my $router = AnyEvent::HTTPD::Router::DefaultDispatcher->new();
$router->add_route( make_route_param GET => '/index.txt' );
$router->add_route( make_route_param GET => '/foo/bar' );

my $req;
$req = MockedRequest->new(GET => 'http://localhost/index.txt');
is $router->match($httpd, $req), 1, 'matched 1';
$req = MockedRequest->new(GET => 'http://localhost/foo/bar');
is $router->match($httpd, $req), 1, 'matched 2';
$req = MockedRequest->new(GET => 'http://localhost/unknown');
is $router->match($httpd, $req), 0, 'not matched';

done_testing;

