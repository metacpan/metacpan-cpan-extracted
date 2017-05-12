#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib/';

use Test::More tests => 34;

use Test::Exception;
use Test::HTTP::Server::Simple;
use Test::WWW::Mechanize;

BEGIN {
    use_ok('CGI::Application::Server');
    use_ok('MyCGIApp');
}

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
    '/index.cgi' => 'MyCGIApp'
});
is_deeply($server->entry_points, { '/index.cgi' => 'MyCGIApp' }, '... we have an entry point now');

dies_ok {
    $server->entry_points([]);    
} '... entry points must be a HASH';

dies_ok {
    $server->entry_points('....');    
} '... entry points must be a HASH';

is($server->document_root, '.', '... got the default server root');
$server->document_root('./t/htdocs');
is($server->document_root, './t/htdocs', '... got the new server root');

dies_ok {
    $server->document_root('./t/nothing');    
} '... cannot assign a doc root that does not exist';

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

$mech->get_ok($url_root.'/index.cgi?rm=mode1', '... got the index.cgi page okay');
$mech->title_is('Hello', '... got the right page title for index.cgi (hello)');

$mech->get_ok($url_root.'/index.cgi?rm=mode2', '... got the index.cgi page okay');
$mech->title_is('Goodbye', '... got the right page title for index.cgi (goodbye)');

$mech->get_ok($url_root.'/index.cgi?rm=mode4', '... got the index.cgi page okay');
$mech->title_is('Redirect End', '... got the right page title for index.cgi (redirect end)');

$mech->get_ok($url_root.'/index.cgi?rm=mode3', '... got the index.cgi page okay');
$mech->title_is('Redirect End', '... got the right page title for index.cgi (redirect end)');

# test with extra path info after the entry point

$mech->get_ok($url_root.'/index.cgi/test', '... got the index.cgi page okay (even with extra path info)');
$mech->title_is('Hello', '... got the right page title for index.cgi (even with extra path info)');

$mech->get_ok($url_root.'/index.cgi/test?rm=mode1', '... got the index.cgi page okay (even with extra path info)');
$mech->title_is('Hello', '... got the right page title for index.cgi (even with extra path info)');

$mech->get_ok($url_root.'/index.cgi/test?rm=mode2', '... got the index.cgi page okay (even with extra path info)');
$mech->title_is('Goodbye', '... got the right page title for index.cgi (even with extra path info)');

$mech->get_ok($url_root.'/index.cgi/test?rm=mode4', '... got the index.cgi page okay (even with extra path info)');
$mech->title_is('Redirect End', '... got the right page title for index.cgi (even with extra path info)');

$mech->get_ok($url_root.'/index.cgi/test?rm=mode3', '... got the index.cgi page okay (even with extra path info)');
$mech->title_is('Redirect End', '... got the right page title for index.cgi (even with extra path info)');
