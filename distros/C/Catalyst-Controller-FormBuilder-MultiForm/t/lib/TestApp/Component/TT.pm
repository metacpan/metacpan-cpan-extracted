# This TestApp is used with permission from Juan Camacho, and is from the 0.03 
# release of his Catalyst::Controller::FormBuilder module

package TestApp::Component::TT;

use strict;
use base 'Catalyst::View::TT';

sub new {
    my $self = shift;
    $self->config(
        {
            INCLUDE_PATH => [
                TestApp->path_to( 'root', 'src', 'Template-Toolkit' ),
                TestApp->path_to( 'root', 'lib', 'Template-Toolkit' ),
            ],
            TEMPLATE_EXTENSION => '',
            CATALYST_VAR       => 'Catalyst',
            TIMER              => 0,
        }
    );
    return $self->NEXT::new(@_);
}

1;
