package TestAppClear;

use base 'CGI::Application';

use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::MessageStack;

use Test::More;

## TEST PLAN ##
#* messages
# * first request:
#    - establish session
#    - push in a few messages
# * second request:
#    - pass in session
#    - call messages() and compare data structure
# * third request:
#    - pass in session
#    - call messages() with scope and compare data structure
# * fourth request:
#    - pass in session
#    - call messages() with classification and compare data structure
# * fifth request:
#    - pass in session
#    - call messages() with both scope & classification and compare data structure
#FILES: 04-messages.t, TestMessages.pm

sub setup {
    my $self = shift;
    $self->mode_param( 'rm' );
    $self->run_modes( [ qw( start second third fourth fifth cleanup ) ] );
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
    $session->clear( [ '__CAP_MessageStack_Stack' ] ); # muhahahahaha
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
            -scope          => 'fourth',
            -message        => 'got your stuff updated',
            -classification => 'INFO',
        );
    $self->push_message(
            -scope          => 'fourth',
            -message        => 'another info',
            -classification => 'INFO',
        );
    $self->push_message(
            -scope          => 'fourth',
            -message        => 'some bad stuff',
            -classification => 'ERROR',
        );
    return "all set";
}

sub second {
    my $self = shift;
    my $session = $self->session;
    $self->clear_messages();
    my $messages = $self->messages();
    
    my $expectation = [
        ];

    my $message = 'failed';
    if ( is_deeply( $expectation, $messages, undef ) ) {
        $message = 'succeeded';
    }
    return $message;
}

sub third {
    my $self = shift;
    my $session = $self->session;
    $self->clear_messages( -scope => 'fourth' );
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

sub fourth {
    my $self = shift;
    my $session = $self->session;
    $self->clear_messages( -classification => 'ERROR' );
    my $messages = $self->messages();
    my $expectation = [
            { -message => 'this is a test' },
            { -message => 'this is another test', -classification => 'INFO' },
            { -scope => 'fourth', -message => 'got your stuff updated', -classification => 'INFO' },            
            { -scope => 'fourth', -message => 'another info', -classification => 'INFO' },            
        ];

    my $message = 'failed';
    if ( is_deeply( $expectation, $messages, undef ) ) {
        $message = 'succeeded';
    }
    return $message;
}

sub fifth {
    my $self = shift;
    my $session = $self->session;
    $self->clear_messages( -scope => 'fourth', -classification => 'ERROR' );
    my $messages = $self->messages();
    my $expectation = [
            { -message => 'this is a test' },
            { -message => 'this is another test', -classification => 'INFO' },
            { -scope => 'invalid', -message => 'bad password!', -classification => 'ERROR' },
            { -scope => 'start', -message => 'there was a problem', -classification => 'ERROR' },
            { -scope => 'fourth', -message => 'got your stuff updated', -classification => 'INFO' },            
            { -scope => 'fourth', -message => 'another info', -classification => 'INFO' },            
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