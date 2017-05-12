package TestApp::Component::TT;

use strict;
use base 'Catalyst::View::TT';

use MRO::Compat;

sub new {
    my $self = shift;
    $self->config(
        {
            INCLUDE_PATH => [
                TestApp->path_to( 'root', 'src', 'tt2' ),
                TestApp->path_to( 'root', 'lib', 'tt2' ),
            ],
            TEMPLATE_EXTENSION => '.tt',
            CATALYST_VAR       => 'Catalyst',
            TIMER              => 0,
        }
    );
    
    return $self = $self->maybe::next::method(@_)
}

1;
