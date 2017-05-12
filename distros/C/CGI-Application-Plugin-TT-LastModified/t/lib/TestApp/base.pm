package TestApp::base;

use strict;
use base qw(CGI::Application);
use CGI::Application::Plugin::TT;

sub cgiapp_init {
    my $self = shift;
    $self->tt_config(
        TEMPLATE_OPTIONS => {
            INCLUDE_PATH => 't/templates/',
            POST_CHOMP => 1,
            DEBUG => 1,
            },
        );
}

sub setup {
    my $self = shift;
    $self->start_mode( 'test' );
    $self->run_modes([qw( test )]);
}

1;
