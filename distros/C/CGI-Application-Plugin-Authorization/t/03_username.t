#!/usr/bin/perl
use Test::More tests => 3;
use Scalar::Util;
use CGI;

use strict;
use warnings;
use lib './t';

{
    {
        package TestAppUsernameSub;

        use base qw(CGI::Application);
        use CGI::Application::Plugin::Authorization;
    }

    my $cgiapp = TestAppUsernameSub->new();
    $cgiapp->authz->config(
        DRIVER       => [ 'Generic', sub { 1 } ],
        GET_USERNAME => sub { 'get_username' },
    );
    is($cgiapp->authz->username, 'get_username', 'GET_USERNAME returned the correct username');
}


SKIP: {
    eval "require CGI::Application::Plugin::Authentication";
    skip "CGI::Application::Plugin::Authentication required for this test", 1 if $@;

    {
        package TestAppUsernameAuthen;

        use base qw(CGI::Application);
        use CGI::Application::Plugin::Authorization;
        CGI::Application::Plugin::Authentication->import;
    }

    my $query = CGI->new( { authen_username => 'authentication', authen_password => '123' } );

    my $cgiapp = TestAppUsernameAuthen->new( QUERY => $query );
    $cgiapp->authen->config(
        DRIVER => [ 'Generic', { authentication => '123' } ],
    );
    $cgiapp->authz->config(
        DRIVER       => [ 'Generic', sub { 1 } ],
    );
    is($cgiapp->authz->username, 'authentication', 'Authentication provided the correct username');
    undef $cgiapp;

}



{
    {
        package TestAppUsernameRemoteUser;

        use base qw(CGI::Application);
        use CGI::Application::Plugin::Authorization;
    }

    $ENV{REMOTE_USER} = 'remoteuser';
    my $cgiapp = TestAppUsernameRemoteUser->new();
    $cgiapp->authz->config(
        DRIVER       => [ 'Generic', sub { 1 } ],
    );
    is($cgiapp->authz->username, 'remoteuser', 'REMOTE_USER returned the correct username');
}


