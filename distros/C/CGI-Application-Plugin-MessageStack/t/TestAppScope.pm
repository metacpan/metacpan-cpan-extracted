package TestAppScope;

use base 'CGI::Application';

use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::MessageStack;

## TEST PLAN ##
# * cgiapp w/ html-template
#  * same as before, but check scoping:
#    - in 2nd request, scope info message for non-existent runmode
#    - in 3rd request, check for ! message
#    - in 4th request, scope info message for arrayref runmodes
#    - in 5th request, check for message (1st arrayref value)
#    - in 6th request, check for message (2nd arrayref value)
#    - in 7th request, check for ! message
# FILES: 03-scope.t, TestAppScope.pm, output.TMPL

sub setup {
    my $self = shift;
    $self->mode_param( 'rm' );
    $self->run_modes( [ qw( start second third fourth fifth sixth cleanup ) ] );
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
    my $template = $self->load_tmpl( 'output.TMPL', 'die_on_bad_params' => 0 );
    $template->output;
}

sub second {
    my $self = shift;
    my $session = $self->session;
    $self->push_message(
            -scope          => 'invalid',
            -message        => 'this is a test',
            -classification => 'ERROR',
        );
    return "scoped message pushed";
}

sub third {
    my $self = shift;
    my $session = $self->session;
    my $template = $self->load_tmpl( 'output.TMPL', 'die_on_bad_params' => 0 );
    $template->output;
}

sub fourth {
    my $self = shift;
    my $session = $self->session;
    $self->push_message(
            -scope    => [ qw( fifth sixth ) ],
	    -message  => 'arrayref test',
        );
    return "scoped message with arrayref pushed";
}

sub fifth {
    my $self = shift;
    my $session = $self->session;
    my $template = $self->load_tmpl( 'output.TMPL', 'die_on_bad_params' => 0 );
    $template->output;
}

sub sixth {
    my $self = shift;
    my $session = $self->session;
    my $template = $self->load_tmpl( 'output.TMPL', 'die_on_bad_params' => 0 );
    $template->output;
}

sub cleanup {
    my $self = shift;
    $self->session->delete;
    return "session deleted";
}

1;
