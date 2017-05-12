package Module::Name;
use base 'CGI::Application';

sub setup {
    my $self = shift;
    $self->start_mode('rm1');
    $self->run_modes(
        rm1 => 'rm1',
    ); 
}

sub rm1 {
    my $self = shift;
    return 'Module::Name->rm1';
}

1;
