#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Test::WWW::Mechanize;
use CGI::Application::Server;

{
    package TestApp;
    use base 'CGI::Application';
    
    sub setup {
        my ($self) = @_;
        
        $self->mode_param(path_info => 1);
        $self->run_modes([qw/ foo bar /]);        
    }

    sub foo {
        my ($self) = @_;
        
        return '<HTML><HEAD><TITLE>Hello world!</TITLE></HEAD>'
            . '<BODY><H1>Hello world!</H1><HR></BODY></HTML>';
    }
                                                        
    sub bar {
        my ($self) = @_;
        
        return '<HTML><HEAD><TITLE>Goodbye world!</TITLE></HEAD>'
            . '<BODY><H1>Goodbye world!</H1><HR></BODY></HTML>';
    }
                                                        
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
$server->entry_points({
    '/index.cgi'         => 'TestApp',
});
my $url_root = $server->started_ok("start up my web server");

my $mech = Test::WWW::Mechanize->new();

$mech->get_ok($url_root . '/index.cgi/foo', '...got run mode foo');
$mech->title_is('Hello world!', '... got the right page title for foo');

$mech->get_ok($url_root . '/index.cgi/bar', '...got run mode bar');
$mech->title_is('Goodbye world!', '... got the right page title for bar');

