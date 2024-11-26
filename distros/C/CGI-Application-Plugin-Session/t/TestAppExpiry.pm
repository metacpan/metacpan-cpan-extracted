package TestAppExpiry;

use strict;

use CGI::Application;
use CGI::Application::Plugin::Session;
@TestAppExpiry::ISA = qw(CGI::Application);

sub cgiapp_init {
    my $self = shift;

    my $sid = $self->query->cookie('CGISESSID');
    $self->session_config(
        CGI_SESSION_OPTIONS => [ "driver:File", $sid ],
        DEFAULT_EXPIRY => $ENV{DEFAULT_EXPIRY},
    );
}

sub setup {
    my $self = shift;

    $self->start_mode('test_mode');

    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
    my $self = shift;
    my $output = '';

    my $session = $self->session;

    $output .= "session expiry: (".$session->expires.")\n";
    
    return $output;
}


1;
