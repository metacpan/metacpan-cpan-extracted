package TestAppNoSession;

use base 'CGI::Application';

use CGI::Application::Plugin::MessageStack;

sub setup {
    my $self = shift;
    $self->run_modes( [ qw( start ) ] );
    $self->tmpl_path( './t' );
}

sub start {
    my $self = shift;
    my $template = $self->load_tmpl( 'output.TMPL', 'die_on_bad_params' => 0 );
    $self->push_message(
            -scope          => 'start',
            -message        => 'this is a test',
            -classification => 'ERROR',
        );
    $template->output;
}

1;