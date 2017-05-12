# ============================================================================
package Business::UPS::Tracking::Shipment::SmallPackage;
# ============================================================================
use utf8;
use 5.0100;

use Moose;
extends 'Business::UPS::Tracking::Shipment';

use Business::UPS::Tracking::Element::Package;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Shipment::SmallPackage - A small package shipment

=head1 DESCRIPTION


This class represents an small package shipment and extends 
L<Business::UPS::Tracking::Shipment>. Usually it is created 
automatically from a L<Business::UPS::Tracking::Response> object.

=head1 ACCESSORS

Same as L<Business::UPS::Tracking::Shipment>

=head2 Package

List of packages (L<Business::UPS::Tracking::Element::Package>)

=cut

has 'Package' => (
    is      => 'ro',
    isa     => 'ArrayRef[Business::UPS::Tracking::Element::Package]',
    traits  => ['Printable'],
    documentation   => 'Package',
    lazy_build      => 1,
);

sub _build_Package {
    my ($self) = @_;

    my @nodes = $self->xml->findnodes('Package');
    my $return = [];
    foreach my $node (@nodes) {
        push @$return,Business::UPS::Tracking::Element::Package->new(
            xml => $node,
        );
    }
    return $return;
}



=head1 METHODS

=head2 ShipmentType

Returns 'Small Package'

=cut

sub ShipmentType {
    return 'Small Package';
}

=head2 meta

Moose meta method

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
