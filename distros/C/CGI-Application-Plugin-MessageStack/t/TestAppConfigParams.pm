package TestAppConfigParams;

use base 'CGI::Application';

use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::MessageStack;

use Test::More;

## TEST PLAN ##
#* capms_config w/ parameter name overrides
# * cgiapp w/ parameter name configs
#  * first request
#    - establish session
#    - call capms_config with parameter name overrides
#    - push in some messages
#  * second request
#    - pass in session
#    - load original template (output.TMPL) and check for no message
#  * third request
#    - pass in session
#    - load in different template (output_params.TMPL) and check for message
#FILES: 09-capms_config_params.t, TestAppConfigParams.pm, output.TMPL, output_params.TMPL

sub setup {
    my $self = shift;
    $self->mode_param( 'rm' );
    $self->run_modes( [ qw( start second third fourth cleanup ) ] );
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
            -scope          => 'third',
            -message        => 'got your stuff updated',
            -classification => 'INFO',
        );
    $self->push_message(
            -scope          => 'third',
            -message        => 'another info',
            -classification => 'INFO',
        );
    $self->push_message(
            -scope          => 'third',
            -message        => 'some bad stuff',
            -classification => 'ERROR',
        );
    $self->capms_config(
            -loop_param_name               => 'MyOwnLoopName',
            -message_param_name            => 'MyOwnMessageName',
            -classification_param_name     => 'MyOwnClassificationName',
        );
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
    my $template = $self->load_tmpl( 'output_params.TMPL', 'die_on_bad_params' => 0 );
    $template->output;
}

sub fourth {
    my $self = shift;
    my $session = $self->session;
    my $messages = $self->messages();
    
    my $expectation = [
            { 'MyOwnMessageName' => 'this is a test' },
            { 'MyOwnMessageName' => 'this is another test', 'MyOwnClassificationName' => 'INFO' },
            { -scope => 'invalid', 'MyOwnMessageName' => 'bad password!', 'MyOwnClassificationName' => 'ERROR' },
            { -scope => 'start', 'MyOwnMessageName' => 'there was a problem', 'MyOwnClassificationName' => 'ERROR' },
            { -scope => 'third', 'MyOwnMessageName' => 'got your stuff updated', 'MyOwnClassificationName' => 'INFO' },            
            { -scope => 'third', 'MyOwnMessageName' => 'another info', 'MyOwnClassificationName' => 'INFO' },            
            { -scope => 'third', 'MyOwnMessageName' => 'some bad stuff', 'MyOwnClassificationName' => 'ERROR' },            
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