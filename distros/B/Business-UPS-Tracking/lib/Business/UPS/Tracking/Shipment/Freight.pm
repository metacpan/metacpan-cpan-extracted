# ============================================================================
package Business::UPS::Tracking::Shipment::Freight;
# ============================================================================
use utf8;
use 5.0100;

use Moose;
extends 'Business::UPS::Tracking::Shipment';

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Shipment::Freight - A freight shipment

=head1 DESCRIPTION

This class has not yet been implemented (patches welcome). If you need to 
work with freight shipments you still can access the xml tree via 
C<$shipment-E<gt>xml>.

This class represents an freight shipment and extends 
L<Business::UPS::Tracking::Shipment>. Usually it is created 
automatically from a L<Business::UPS::Tracking::Response> object.

=head1 ACCESSORS

Same as L<Business::UPS::Tracking::Shipment>

=cut

sub BUILD {
    warn('Business::UPS::Tracking::Shipment::Freight not yet implemented');   
    return;
}

=head1 METHODS

=head2 ShipmentType

Returns 'Freight'

=cut

sub ShipmentType {
    return 'Freight';
}

=head2 meta

Moose meta method

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
