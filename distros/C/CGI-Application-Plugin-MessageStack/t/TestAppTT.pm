package TestAppTT;

use base 'CGI::Application';

use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::MessageStack;
use CGI::Application::Plugin::TT 0.09;

## TEST PLAN ##
# * cgiapp w/ html-template
#  * first request:
#     - establish session
#     - check output for ! message
#  * second request:
#     - pass in session
#     - push an info message
#  * third request:
#     - pass in session
#     - check output for message
#     - check message for proper classification
# FILES: 02-check_output.t, TestAppOutput.pm, output.TMPL

sub setup {
    my $self = shift;
    $self->mode_param( 'rm' );
    $self->run_modes( [ qw( start second third cleanup ) ] );
    $self->tmpl_path( './t' );
    $self->tt_include_path( './t' );
}

sub cgiapp_init {
    my $self = shift;
    $self->session_config({
            CGI_SESSION_OPTIONS => [ "driver:File", $self->query, {Directory=>'t/'} ],
            SEND_COOKIE         => 1,
            COOKIE_PARAMS       => {
                                     -path    => '/',
                                     -domain  => 'mydomain.com',
                                     -expires => '+3M',
                                   },
        });
}

sub start {
    my $self = shift;
    my $session = $self->session;
    return $self->tt_process( 'output.tt' );
}

sub second {
    my $self = shift;
    my $session = $self->session;
    $self->push_message(
            -message        => 'this is a test',
            -classification => 'ERROR',
        );
    return "message pushed";
}

sub third {
    my $self = shift;
    my $session = $self->session;
    return $self->tt_process( 'output.tt' );
}

sub cleanup {
    my $self = shift;
    $self->session->delete;
    return "session deleted";
}

1;
