# ============================================================================
package Business::UPS::Tracking::Shipment;
# ============================================================================
use utf8;
use 5.0100;

use Moose;
with qw(Business::UPS::Tracking::Role::Print
    Business::UPS::Tracking::Role::Builder);

use Business::UPS::Tracking::Utils;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Shipment - Base class for shipments

=head1 DESCRIPTION

This class is a base class for 
L<Business::UPS::Tracking::Shipment::SmallPackage> and 
L<Business::UPS::Tracking::Shipment::Freight>. Usually it is created 
automatically from a L<Business::UPS::Tracking::Response> object. It provides
accessors common to all shipment types.

=head1 ACCESSORS

=head2 xml

L<XML::LibXML::Node> node of the shipment.

=head2 ScheduledDelivery

Scheduled delivery date and time. Returns a L<DateTime> object.

=head2 PickupDate

Pickup date. Returns a L<DateTime> object.

=head2 ShipperNumber

Shipper UPS customer number.

=head2 ShipperAddress

Shipper address. Returns a L<Business::UPS::Tracking::Element::Address>
object.

=head2 ShipmentWeight

Shipment weight. Returns a L<Business::UPS::Tracking::Element::Weight>
object.

=head2 ShipToAddress

Shipment destination address. Returns a 
L<Business::UPS::Tracking::Element::Address> object.

=head2 Service

Service code and description. 
Returns a L<Business::UPS::Tracking::Element::Code> object.

=head2 ShipmentReferenceNumber

Reference number for the whole shipment as provided by the shipper. Returns a 
L<Business::UPS::Tracking::Element::ReferenceNumber> object.

=cut

has 'xml' => (
    is      => 'ro',
    required=> 1,
    isa     => 'XML::LibXML::Node',
);
has 'ScheduledDelivery' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Type::Date]',
    traits  => ['Printable'],
    lazy_build      => 1,
    documentation   => 'Scheduled delivery date',
);
has 'PickupDate' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Type::Date]',
    traits  => ['Printable'],
    documentation   => 'Pickup date',
    lazy_build      => 1,
);
has 'ShipperNumber' => (
    is      => 'ro',
    isa     => 'Str',
    traits  => ['Printable'],
    documentation   => 'Shipper UPS customer number',
    lazy_build      => 1,
);
has 'ShipperAddress' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Element::Address]',
    traits  => ['Printable'],
    documentation   => 'Shipper address',
    lazy_build      => 1,
);
has 'ShipmentWeight' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Element::Weight]',
    traits  => ['Printable'],
    documentation => 'Shipment weight',
    lazy_build    => 1,
);
has 'ShipToAddress' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Element::Address]',
    traits  => ['Printable'],
    documentation   => 'Destination address',
    lazy_build      => 1,
);
has 'Service' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Element::Code]',
    traits  => ['Printable'],
    documentation   => 'Service',
    lazy_build      => 1,
);
has 'ReferenceNumber' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Element::ReferenceNumber]',
    traits  => ['Printable'],
    documentation   => 'Reference number',
    lazy_build      => 1,
);
has 'ShipmentIdentificationNumber' => (
    is      => 'ro',
    isa     => 'Str',
    traits  => ['Printable'],
    documentation   => 'Identification number',
    lazy_build      => 1,
);

sub _build_ScheduledDelivery {
    my ($self) = @_;

    my $datestr = $self->xml->findvalue('ScheduledDeliveryDate');
    my $date    = Business::UPS::Tracking::Utils::parse_date($datestr);

    my $timestr = $self->xml->findvalue('ScheduledDeliveryTime');
    $date = Business::UPS::Tracking::Utils::parse_time( $timestr, $date );

    return $date;
}

sub _build_PickupDate {
    my ($self) = @_;

    my $datestr = $self->xml->findvalue('PickupDate');
    return Business::UPS::Tracking::Utils::parse_date($datestr);
}

sub _build_ShipperNumber {
    my ($self) = @_;
    
    return $self->xml->findvalue('Shipper/ShipperNumber');
}

sub _build_ShipperAddress {
    my ($self) = @_;
    
    return $self->build_address('Shipper/Address');
}

sub _build_ShipmentWeight {
    my ($self) = @_;
    
    return $self->build_weight('ShipmentWeight');
}

sub _build_ShipToAddress {
    my ($self) = @_;
    
    return $self->build_address('ShipTo/Address');
}

sub _build_Service {
    my ($self) = @_;
    
    return $self->build_code('Service');
}

sub _build_ReferenceNumber {
    my ($self) = @_;
    
    return $self->build_referencenumber('ReferenceNumber');
}

sub _build_ShipmentIdentificationNumber {
    my ($self) = @_;

    return $self->xml->findvalue('ShipmentIdentificationNumber')
        || undef;
}

=head1 METHODS

=head2 ShipmentType

Returns the shipment type. Either 'Freight' or 'Small Package'

=cut

sub ShipmentType {
    Business::UPS::Tracking::X->throw("__PACKAGE__ is an abstract class");
    return;
}

=head2 meta

Moose meta method

=cut


__PACKAGE__->meta->make_immutable;
no Moose;
1;
