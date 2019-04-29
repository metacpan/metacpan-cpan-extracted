#!perl
use lib 't/lib';
use common::sense;

use Test::More;
use AnyEvent::HTTPD::Router;
use MockedRequest;

my %param_expectation;

sub make_route_param {
    my $method = shift;
    my $url    = shift;
    my $cb     = sub {
        my $httpd = shift;
        my $req   = shift;
        my $param = shift;
        is $req->method, $method, 'method is correct';
        is_deeply $param, \%param_expectation, 'parameters are correct'
    };
    return ([$method], $url, $cb);
}

my $httpd  = 'not needed here';
my $router = AnyEvent::HTTPD::Router::DefaultDispatcher->new();
$router->add_route( make_route_param GET => '/foo/*' );
$router->add_route( make_route_param GET => '/bar/*bar' );
$router->add_route( make_route_param GET => '/foobar/yada*' );

my $req;
$req = MockedRequest->new(GET => 'http://localhost/foo/index.html');
%param_expectation = ('*' => 'index.html');
is $router->match($httpd, $req), 1, 'matched 1';

$req = MockedRequest->new(GET => 'http://localhost/foo/bar/yada');
%param_expectation = ( '*' => 'bar/yada');
is $router->match($httpd, $req), 1, 'matched 2';

$req = MockedRequest->new(GET => 'http://localhost/bar/*bar');
%param_expectation = ();
is $router->match($httpd, $req), 1, 'matched literal';

$req = MockedRequest->new(GET => 'http://localhost/foobar/yada*');
%param_expectation = ();
is $router->match($httpd, $req), 1, 'matched literal';

done_testing;

