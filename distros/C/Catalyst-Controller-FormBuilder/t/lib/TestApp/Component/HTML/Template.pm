package TestApp::Component::HTML::Template;

use strict;
use base 'Catalyst::View::HTML::Template';

use MRO::Compat;

sub new {
    my $self = shift;

    $self->config(
        {
            die_on_bad_params => 0,
            path              => 
                TestApp->path_to( 'root', 'src', 'tmpl' ) . '',
        },
    );
    
    return $self = $self->maybe::next::method(@_)
}

1;
