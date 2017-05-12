#!/usr/bin/perl

use warnings;
use strict;
use CGI::Application::Server;
use Test::More tests => 5;
use Test::WWW::Mechanize;
use lib 't/lib';
use ReplaceQueryObject;

my $app = ReplaceQueryObject->new();

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
    '/one.cgi' => $app,
    '/two.cgi' => 'ReplaceQueryObject',
});

my $url_root = $server->started_ok("start up my web server");

my $mech = Test::WWW::Mechanize->new();

$mech->get($url_root . '/one.cgi?text=foo');
$mech->title_is('foo', '... got foo with CGI::Application object');

$mech->get($url_root . '/one.cgi?text=bar');
$mech->title_is('bar', '... got bar with CGI::Application object');

$mech->get($url_root . '/two.cgi?text=foo');
$mech->title_is('foo', '... got foo with CGI::Application class');

$mech->get($url_root . '/two.cgi?text=bar');
$mech->title_is('bar', '... got bar with CGI::Application class');

