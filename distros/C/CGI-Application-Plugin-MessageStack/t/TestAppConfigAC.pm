package TestAppConfigAC;

use base 'CGI::Application';

use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::MessageStack;

use Test::More;

## TEST PLAN ##
#* capms_config w/ Automatic Clearing
# * cgiapp w/ various configuration runmodes
#  * first request
#    - establish session
#    - call capms_config with -automatic_clearing
#    - push in some messages
#  * second request
#    - pass in session
#    - check output for message
#  * third request
#    - pass in session
#    - call messages() and compare
#FILES: 08-capms_config_ac.t, TestAppConfigAC.pm, output.TMPL

sub setup {
    my $self = shift;
    $self->mode_param( 'rm' );
    $self->run_modes( [ qw( start second third cleanup ) ] );
    $self->tmpl_path( './t' );
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
    $self->push_message(
            -message        => 'this is a test',
        );
    $self->push_message(
            -message        => 'this is another test',
            -classification => 'INFO',
        );
    $self->push_message(
            -scope          => 'invalid',
            -message        => 'bad password!',
            -classification => 'ERROR',
        );
    $self->push_message(
            -scope          => 'start',
            -message        => 'there was a problem',
            -classification => 'ERROR',
        );
    $self->push_message(
            -scope          => 'second',
            -message        => 'got your stuff updated',
            -classification => 'INFO',
        );
    $self->push_message(
            -scope          => 'second',
            -message        => 'another info',
            -classification => 'INFO',
        );
    $self->push_message(
            -scope          => 'second',
            -message        => 'some bad stuff',
            -classification => 'ERROR',
        );
    $self->capms_config( -automatic_clearing => 1 );
    return "all set";
}

sub second {
    my $self = shift;
    my $session = $self->session();
    my $template = $self->load_tmpl( 'output.TMPL', 'die_on_bad_params' => 0 );
    $template->output;
}

sub third {
    my $self = shift;
    my $session = $self->session;
    my $messages = $self->messages();
    
    my $expectation = [
            { -scope => 'invalid', -message => 'bad password!', -classification => 'ERROR' },
            { -scope => 'start', -message => 'there was a problem', -classification => 'ERROR' },
        ];

    my $message = 'failed';
    if ( is_deeply( $expectation, $messages, undef ) ) {
        $message = 'succeeded';
    }
    return $message;
}

sub cleanup {
    my $self = shift;
    $self->session->delete;
    return "session deleted";
}

1;