package TestApp::FauxProvider;

use Template::Constants;

use base qw(Template::Provider);

sub fetch {
    my $self = shift();
    my $name = shift();
    
    my $data = {
        name    => $name,
        path    => $name,
        text    => 'Faux-tastic!',
        'time'  => time(),
        load    => time()
    };

    my ($page, $error) = $self->_compile($data);
    return ($page->{'data'}, $error);
}

1;