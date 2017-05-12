package TestAppConfigNoSession;

## TEST PLAN ##
# * capms_config w/ dont_use_session
#  * cgiapp w/ dont_use_session config
#   * first request
#     - push in some messages
#     - check for no messages
#     - load_tmpl and check for output
#   * second request
#     - load_tmpl and check for no messages in output
# FILES: 10-capms_config_no_session.t, TestAppConfigNoSession.pm, output.TMPL


use base 'CGI::Application';

use CGI::Application::Plugin::MessageStack;

sub setup {
    my $self = shift;
    $self->run_modes( [ qw( start second ) ] );
    $self->tmpl_path( './t' );
    $self->capms_config( -dont_use_session => 1 );
}

sub start {
    my $self = shift;
    $self->push_message(
            -scope          => 'start',
            -message        => 'this is a test',
            -classification => 'ERROR',
        );
    my $template = $self->load_tmpl( 'output.TMPL', 'die_on_bad_params' => 0 );
    $template->output;
}

sub second {
    my $self = shift;
    my $template = $self->load_tmpl( 'output.TMPL', 'die_on_bad_params' => 0 );
    $template->output;
}

1;