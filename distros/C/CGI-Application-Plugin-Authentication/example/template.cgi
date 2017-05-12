#!/usr/bin/perl 

#
# Sample application [Templates]
#
# This example is a bit more realistic than the sample.cgi and basic.cgi.
# It is intended to show how you can control the style of the Basic login form.
# You need to copy the templates and the contents of the httpdocs
# to their appropriate places for you server. 
# Unless you change the .cgi script to use a local copy,
# you will also need access to the internet so the script can load
# some javascript files from YUI.
#
# The only valid username/password
# combination is 'test' and '123'.
#

use strict;
use warnings;
use Readonly;

# This bit needs to be modified for the local system.
Readonly my $TEMPLATE_DIR => 'example/templates';

{

    package SampleLogin;

    use base ("CGI::Application::Plugin::HTDot", "CGI::Application");

    use CGI::Application::Plugin::Session;
    use CGI::Application::Plugin::Authentication;
    use CGI::Application::Plugin::AutoRunmode;
    use CGI::Application::Plugin::Authentication::Display::Basic;
    use CGI::Carp qw(fatalsToBrowser);

    my %config = (
        DRIVER         => [ 'Generic', { test => '123' } ],
        STORE          => 'Cookie',
        LOGOUT_RUNMODE => 'one',
        LOGIN_RUNMODE => 'login',
    );
    SampleLogin->authen->config(%config);
    SampleLogin->authen->protected_runmodes('two');

    sub setup {
        my $self = shift;
        $self->start_mode('one');
    }

    sub one : Runmode {
        my $self = shift;
        my $tmpl_obj = $self->load_tmpl('one.tmpl');
        return $tmpl_obj->output;
    }

    sub login : Runmode {
        my $self = shift;
        my $tmpl_obj = $self->load_tmpl('login.tmpl');
        my $display =
        CGI::Application::Plugin::Authentication::Display::Basic->new($self);
        $tmpl_obj->param(login => $display);
        return $tmpl_obj->output;
    }

    sub two : Runmode {
        my $self = shift;
        my $tmpl_obj = $self->load_tmpl('two.tmpl');
        my $display =
        CGI::Application::Plugin::Authentication::Display::Basic->new($self);
        $tmpl_obj->param(login => $display);
        return $tmpl_obj->output;
    }
}

SampleLogin->new(TMPL_PATH=>$TEMPLATE_DIR)->run;

