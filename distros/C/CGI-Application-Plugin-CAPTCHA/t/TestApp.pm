package TestApp;

use strict;
use base "CGI::Application";
use CGI::Application::Plugin::CAPTCHA;

sub setup
{
    my $self = shift;

    $self->start_mode('create');
    $self->run_modes([ qw/create/ ]);
}

sub create 
{
    my $self = shift;
    return $self->captcha_create;
}

1;

