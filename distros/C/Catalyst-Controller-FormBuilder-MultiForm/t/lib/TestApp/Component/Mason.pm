# This TestApp is used with permission from Juan Camacho, and is from the 0.03 
# release of his Catalyst::Controller::FormBuilder module

package TestApp::Component::Mason;

use strict;
use base 'Catalyst::View::Mason';

sub new {
    my $self = shift;

    my $comp_root = TestApp->path_to( 'root', 'src', 'Mason' );
    $self->config->{comp_root} = "$comp_root";

    return $self->NEXT::new(@_);
}

1;
