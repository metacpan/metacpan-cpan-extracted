#!perl
use lib 't/lib';
use common::sense;

use Test::More;
use AnyEvent::HTTPD::Router;

my $httpd = AnyEvent::HTTPD::Router->new();

is_deeply $httpd->allowed_methods, [qw(GET HEAD POST)], 'initial default routes';

$httpd->{allowed_methods} = [];

is_deeply $httpd->allowed_methods, [], 'removed all methods';

$httpd->reg_routes( ':custom' => '/yada' => sub {} );

is_deeply $httpd->allowed_methods, [qw(GET POST)], 'custom methods use GET or POST';

$httpd->reg_routes( PUT => '/yada' => sub {} );

is_deeply $httpd->allowed_methods, [qw(GET POST PUT)], 'PUT was added';

done_testing;

