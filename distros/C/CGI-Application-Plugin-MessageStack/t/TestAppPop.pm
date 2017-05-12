package TestAppPop;

use Test::More;

use base 'CGI::Application';

use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::MessageStack;

## TEST PLAN ##
#* pop_message
# * first request:
#    - establish session
#    - clear private session var
#    - push in a few messages
# * second request:
#    - pass in session
#    - call pop_message() and compare
# * recall first request
# * third request:
#    - pass in session
#    - call pop_message() with scope and compare
# * recall first request
# * fourth request:
#    - pass in session
#    - call pop_message() with classification and compare
# * recall first request
# * fifth request:
#    - pass in session
#    - call pop_message() with scope & classification and compare
# * sixth request:
#    - pass in session
#    - compare the remaining messages()
#FILES: 06-pop_message.t, TestAppPop.pm

sub setup {
    my $self = shift;
    $self->mode_param( 'rm' );
    $self->run_modes( [ qw( start second third fourth fifth sixth cleanup ) ] );
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
    my $message = $self->pop_message();
    return ( $message eq 'some bad stuff' ) ? 'succeeded' : 'failed';
}

sub third {
    my $self = shift;
    my $session = $self->session;
    my $message = $self->pop_message( -scope => 'start' );
    return ( $message eq 'there was a problem' ) ? 'succeeded' : 'failed';
}

sub fourth {
    my $self = shift;
    my $session = $self->session;
    my $message = $self->pop_message( -classification => 'INFO' );
    return ( $message eq 'another info' ) ? 'succeeded' : 'failed';
}

sub fifth {
    my $self = shift;
    my $session = $self->session;
    my $message = $self->pop_message( -scope => 'fourth', -classification => 'INFO' );
    return ( $message eq 'got your stuff updated' ) ? 'succeeded' : 'failed';
}

sub sixth {
    my $self = shift;
    my $session = $self->session;
    my $messages = $self->messages();
    
    my $expectation = [
            { -message => 'this is a test' },
            { -message => 'this is another test', -classification => 'INFO' },
            { -scope => 'invalid', -message => 'bad password!', -classification => 'ERROR' },
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