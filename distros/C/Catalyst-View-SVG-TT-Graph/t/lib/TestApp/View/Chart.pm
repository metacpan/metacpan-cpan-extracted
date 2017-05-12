package TestApp::View::Chart;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::View::SVG::TT::Graph'; }
#with 'Catalyst::Component::InstancePerContext';

=cut

sub build_per_context_instance{
    my ( $c, $self, $type, %args ) = @_;
    $class = "SVG::TT::Graph::" . ucfirst($type);

    return $class->new();
}

=cut

1;
