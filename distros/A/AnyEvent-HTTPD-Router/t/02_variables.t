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
$router->add_route( make_route_param GET => '/:anything' );
$router->add_route( make_route_param GET => '/:foo/:bar' );

my $req;
$req = MockedRequest->new(GET => 'http://localhost/index.txt');
%param_expectation = (anything => 'index.txt');
is $router->match($httpd, $req), 1, 'matched 1';

$req = MockedRequest->new(GET => 'http://localhost/2/1');
%param_expectation = ( foo => 2, bar => 1);
is $router->match($httpd, $req), 1, 'matched 2';

done_testing;

