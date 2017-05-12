package TestApp::Component::Mason;

use strict;
use base 'Catalyst::View::Mason';

use MRO::Compat;

sub new {
    my $self = shift;

    my $comp_root = TestApp->path_to( 'root', 'src', 'mason' );
    $self->config->{comp_root} = "$comp_root";

    return $self = $self->maybe::next::method(@_)
}

1;
