#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Test::WWW::Mechanize;
use CGI::Application::Server;
use lib 't/lib';
use AppWithParams;

my $app1 = AppWithParams->new(PARAMS => {
    message => 'Hello world!',    
});

my $app2 = AppWithParams->new(PARAMS => {
    message => 'Goodbye world!',    
});

{
    package TestServer;
    use base qw/
        Test::HTTP::Server::Simple
        CGI::Application::Server
    /;
}

my $port = $ENV{CGI_APP_SERVER_TEST_PORT} || 40000 + int(rand(10000));

my $server = TestServer->new($port);
$server->entry_points({
    '/foo/index.cgi'         => $app1,
    '/bar/index.cgi'         => $app2,
});
my $url_root = $server->started_ok("start up my web server");

my $mech = Test::WWW::Mechanize->new();

$mech->get_ok($url_root . '/foo/index.cgi', '...got app1');
$mech->title_is('Hello world!', '... got the right page title for app1');

$mech->get_ok($url_root . '/bar/index.cgi', '...got app1');
$mech->title_is('Goodbye world!', '... got the right page title for app2');

