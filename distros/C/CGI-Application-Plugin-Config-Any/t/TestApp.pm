package TestApp;

use strict;

use CGI::Application;
@TestApp::ISA = qw(CGI::Application);

use CGI::Application::Plugin::Config::Any qw/ :all /;

sub setup {
    my $self = shift;
    $self->start_mode('test_mode');
    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
    my $self = shift;
    return 1;
}


1;
