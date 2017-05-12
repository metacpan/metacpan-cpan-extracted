package MyApp::Module::Rest;
use base 'CGI::Application';

sub setup {
    my $self = shift;
    $self->start_mode('rm1_GET');
    $self->run_modes([qw/
        rm1_GET
        rm1_POST
        rm2_post
        get_rm3 
        rm4
    /]); 
}

sub rm1_GET {
    my $self = shift;
    return 'MyApp::Module::Rest->rm1_GET';
}

sub rm1_POST {
    my $self = shift;
    return 'MyApp::Module::Rest->rm1_POST';
}

sub rm2_post {
    my $self = shift;
    return 'MyApp::Module::Rest->rm2_post';
}

sub get_rm3 {
    my $self = shift;
    return 'MyApp::Module::Rest->get_rm3';
}

sub rm4 {
    my $self = shift;
    return 'MyApp::Module::Rest->rm4';
}


1;
