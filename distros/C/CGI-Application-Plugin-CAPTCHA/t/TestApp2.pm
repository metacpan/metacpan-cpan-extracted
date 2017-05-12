package TestApp2;

use strict;
use base "CGI::Application";
use CGI::Application::Plugin::CAPTCHA;

sub setup
{
    my $self = shift;

    $self->start_mode('create');
    $self->run_modes([ qw/create/ ]);
    $self->captcha_config(
        IMAGE_OPTIONS    => {
            width   => 150,
            height  => 40,
            lines   => 10,
            gd_font => "giant",
            bgcolor => "#FFFF00",
        },
        CREATE_OPTIONS   => [ 'normal', 'rect' ],
        PARTICLE_OPTIONS => [ 300 ],
        SECRET           => 'vbCrfzMCi45TD7Uz4C6fjWvX6us',
        DEBUG            => 1,
    );
}

sub create 
{
    my $self = shift;
    return $self->captcha_create;
}

1;

