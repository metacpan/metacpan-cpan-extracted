# This TestApp is used with permission from Juan Camacho, and is from the 0.03 
# release of his Catalyst::Controller::FormBuilder module

package TestApp::Component::HTML::Template;

use strict;
use base 'Catalyst::View::HTML::Template';

sub new {
    my $self = shift;
    $self->config(
        {
            die_on_bad_params => 0,
            path              => [
                TestApp->path_to( 'root', 'src', 'HTML-Template' ),
            ],
        },
    );
    return $self->NEXT::new(@_);
}

1;
