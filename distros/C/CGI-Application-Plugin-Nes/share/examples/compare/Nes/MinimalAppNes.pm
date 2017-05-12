package MinimalAppNes;
use base 'CGI::Application::Plugin::Nes';
use strict;

# require if exec by .cgi
# $ENV{CGI_APP_NES_DIR} = '/full/path/to/cgi-bin/nes';

sub setup {
    my $self = shift;
    
    $self->start_mode('index');
    $self->mode_param('action');
    $self->run_modes(
        'index'  => 'index',
        'logout' => 'logout',
    );

}

sub index {
    my $self = shift;

    # only three lines of Perl script is necessary for generate form login
    my %nes_tags;
    $nes_tags{'action'} = 'login.nhtml';
    Nes::Singleton->instance->out(%nes_tags);
    
}

sub logout {
    my $self = shift;

    my %nes_tags;
    $nes_tags{'action'} = 'logout.nhtml';
    Nes::Singleton->instance->out(%nes_tags);
    
}

1; 
 
