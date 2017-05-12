#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib/';

use Test::More;

use Test::Exception;
use Test::HTTP::Server::Simple;
use Test::WWW::Mechanize;

unless (eval "require CGI::Application::Dispatch; 1") {
  plan skip_all => "CGI::Application::Dispatch required for these tests";
} else {
  plan tests => 19;
}

use_ok('CGI::Application::Server');
use_ok('MyCGIApp');
use_ok('MyCGIApp::Dispatch');

{
    package TestServer;
    use base qw/
        Test::HTTP::Server::Simple
        CGI::Application::Server
    /;
}

my $port = $ENV{CGI_APP_SERVER_TEST_PORT} || 40000 + int(rand(10000));

my $server = TestServer->new($port);
isa_ok($server, 'CGI::Application::Server');
isa_ok($server, 'HTTP::Server::Simple');

is_deeply($server->entry_points, {}, '... no entry-point yet');
$server->entry_points({
    '/index.cgi' => 'MyCGIApp',
    '/bar'       => 'MyCGIApp::Dispatch',
});

is_deeply(
  $server->entry_points,
  {
    '/index.cgi' => 'MyCGIApp',
    '/bar'       => 'MyCGIApp::Dispatch',
  },
  '... we have an entry point now',
);

$server->document_root('./t/htdocs');
is($server->document_root, './t/htdocs', '... got the new server root');

# ignore the warnings for now, 
# they are too hard to test really
local $SIG{__WARN__} = sub { 1 };

my $url_root = $server->started_ok("start up my web server");

my $mech = Test::WWW::Mechanize->new();

# test our static index page

$mech->get_ok($url_root.'/index.html', '... got the index.html page okay');
$mech->title_is('Test Static Index Page', '... got the right page title for index.html');

# test out entry point page

$mech->get_ok($url_root.'/index.cgi', '... got the index.cgi page start-point okay');
$mech->title_is('Hello', '... got the right page title for index.cgi');

# test with query params

$mech->get_ok($url_root.'/bar/foo/mode1', '... got mode1 via dispatch');
$mech->title_is('Hello', '... got the right page title for mode1 (hello)');

$mech->get_ok($url_root.'/bar/foo/mode2', '... got mode2 via dispatch');
$mech->title_is('Goodbye', '... got the right page title for mode2 (bye)');

$mech->get_ok($url_root.'/bar/foo/mode3', '... got mode3, get redir');
$mech->title_is('Redirect End', '... got the right page title for mode4');
