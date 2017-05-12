package MyTestApp;
use base 'CGI::Application';
use CGI::Application::Plugin::RequireSSL;

sub setup {
    my $self = shift;
    $self->start_mode('mode1');
    $self->run_modes([qw/mode1 mode2/]);
}

sub mode1 : RequireSSL {
    'called mode1';
}
 
sub mode2 {
    'called mode2';
}

1;
