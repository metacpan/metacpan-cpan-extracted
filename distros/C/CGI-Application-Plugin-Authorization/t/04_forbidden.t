#!/usr/bin/perl
use Test::More tests => 3;
use Test::Exception;
use Scalar::Util;

use strict;
use warnings;
use lib './t';

{
    {
        package TestAppForbidden;

        use base qw(CGI::Application);
        use CGI::Application::Plugin::Authorization;

        sub setup {
            my $self = shift;
            $self->start_mode('one');
            $self->run_modes([qw(one)]);
        }

        sub one {
            my $self = shift;
            return $self->authz->forbidden;
        }

    }

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $cgiapp = TestAppForbidden->new();
    my $results = $cgiapp->run;

    like($results, qr/<title>Forbidden<\/title>/, "authz_forbidden worked correctly");
}

{
    {
        package TestAppForbiddenRunmode;

        use base qw(CGI::Application);
        use CGI::Application::Plugin::Authorization;

        __PACKAGE__->authz->config(
            FORBIDDEN_RUNMODE => 'myforbidden',
        );

        sub setup {
            my $self = shift;
            $self->start_mode('one');
            $self->run_modes([qw(one myforbidden)]);
        }

        sub one {
            my $self = shift;
            return $self->authz->forbidden;
        }

        sub myforbidden {
            return 'myforbidden runmode';
        }

    }

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $cgiapp = TestAppForbiddenRunmode->new();
    my $results = $cgiapp->run;

    like($results, qr/myforbidden runmode/, "forbidden returned the custom runmode");
}

{
    {
        package TestAppForbiddenURL;

        use base qw(CGI::Application);
        use CGI::Application::Plugin::Authorization;

        __PACKAGE__->authz->config(
            FORBIDDEN_URL => '/myforbidden.html',
        );

        sub setup {
            my $self = shift;
            $self->start_mode('one');
            $self->run_modes([qw(one)]);
        }

        sub one {
            my $self = shift;
            return $self->authz->forbidden;
        }

        sub myforbidden {
            return 'myforbidden runmode';
        }

    }

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $cgiapp = TestAppForbiddenURL->new();
    my $results = $cgiapp->run;

    like($results, qr/Location:\s+\/myforbidden\.html/, "forbidden returned the custom URL");
}

