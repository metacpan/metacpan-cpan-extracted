package TestAppBasic;

use strict;

use CGI::Application;
use CGI::Application::Plugin::DetectAjax;

@TestAppBasic::ISA = qw(CGI::Application);

sub setup {
    my $self = shift;
    $self->start_mode('test_mode');
    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
    my $self = shift;

    return $self->is_ajax;
}

1;
