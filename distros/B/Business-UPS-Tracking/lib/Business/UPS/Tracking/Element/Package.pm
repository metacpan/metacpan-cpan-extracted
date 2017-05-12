# ============================================================================
package Business::UPS::Tracking::Element::Package;
# ============================================================================
use utf8;
use 5.0100;

use Moose;
with qw(Business::UPS::Tracking::Role::Print
    Business::UPS::Tracking::Role::Builder);

use Business::UPS::Tracking::Utils;
use Business::UPS::Tracking::Element::Activity;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Element::Package - A small freight package
  
=head1 DESCRIPTION

This class represents an small freight package. Usually it is created 
automatically from a L<Business::UPS::Tracking::Shipment> object.

=head1 ACCESSORS

=head2 xml

Original L<XML::LibXML::Node> node.

=head2 Activity 

Arrayref of L<Business::UPS::Tracking::Element::Activity> objects
ordered by activity date and time. Check the first element in the list for the
most recent status. 

=head2 RescheduledDelivery

Date and time of rescheduled delivery attempt. Returns a L<DateTime> object.

Returns a L<Business::UPS::Tracking::Element::Address> object.

=head2 ReturnToAddress

Returns a L<Business::UPS::Tracking::Element::Address> object.

=head2 SignatureRequired

Returns 'A' (adult signature), 'S' (signature) or undef (no signature 
required).

=head2 PackageWeight

Package weight. Returns a L<Business::UPS::Tracking::Element::Weight> object.

=head2 TrackingNumber

UPS tracking number.

=head2 RerouteAddress

Returns a L<Business::UPS::Tracking::Element::Address> object.

=cut

has 'xml' => (
    is       => 'ro',
    isa      => 'XML::LibXML::Node',
    required => 1,
);
has 'RerouteAddress' => (
    is    => 'ro',
    isa   => 'Maybe[Business::UPS::Tracking::Element::Address]',
    traits  => ['Printable'],
    documentation   => 'Reroute address',
    lazy_build      => 1,
);
has 'ReturnToAddress' => (
    is    => 'ro',
    isa   => 'Maybe[Business::UPS::Tracking::Element::Address]',
    traits  => ['Printable'],
    documentation   => 'Return address',
    lazy_build      => 1,
);
has 'Activity' => (
    is    => 'ro',
    isa   => 'ArrayRef[Business::UPS::Tracking::Element::Activity]',
    traits  => ['Printable'],
    lazy_build      => 1,
);
has 'SignatureRequired' => (
    is    => 'ro',
    isa   => 'Maybe[Str]',
    traits  => ['Printable'],
    documentation   => 'Signature required',
    lazy_build      => 1,
);
has 'Message' => (
    is    => 'ro',
    isa   => 'ArrayRef[Business::UPS::Tracking::Element::Code]',
    traits  => ['Printable'],
    documentation   => 'Message',
    lazy_build      => 1,
);
has 'PackageWeight' => (
    is    => 'ro',
    isa   => 'Maybe[Business::UPS::Tracking::Element::Weight]',
    traits  => ['Printable'],
    documentation   => 'Weight',
    lazy_build      => 1,
);
has 'ReferenceNumber' => (
    is      => 'ro',
    isa     => 'ArrayRef[Business::UPS::Tracking::Element::ReferenceNumber]',
    traits  => ['Printable'],
    documentation   => 'Reference number',
    lazy_build      => 1,
);
has 'ProductType' => (
    is    => 'ro',
    isa   => 'Maybe[Str]',
    traits  => ['Printable'],
    documentation   => 'Product type',
    lazy_build      => 1,
);
has 'TrackingNumber' => (
    is  => 'ro',
    isa => 'Maybe[Business::UPS::Tracking::Type::TrackingNumber]',
    traits  => ['Printable'],
    documentation   => 'Tracking number',
    lazy_build      => 1,
);
has 'RescheduledDelivery' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Type::Date]',
    traits  => ['Printable'],
    documentation   => 'Rescheduled delivery date',
    lazy_build      => 1,
);

sub _build_RerouteAddress {
    my ($self) = @_;

    return $self->build_address( 'Reroute/Address' );
}

sub _build_ReturnToAddress {
    my ($self) = @_;

    return $self->build_address( 'ReturnTo/Address' );
}

sub _build_PackageWeight {
    my ($self) = @_;

    return $self->build_weight( 'PackageWeight' );
}

sub _build_Message {
    my ($self) = @_;

    my @nodes = $self->xml->findnodes('Message');
    my $return = [];
    foreach my $node (@nodes) {
        push @$return,Business::UPS::Tracking::Element::Code->new(
            xml => $node,
        );
    }
    return $return;
}



sub _build_Activity {
    my ($self) = @_;

    my @nodes = $self->xml->findnodes('Activity');
    my $return = [];
    my @temp;
    
    foreach my $node (@nodes) {
        push @temp,Business::UPS::Tracking::Element::Activity->new(
            xml => $node,
        );
    }
    return [ sort { $b->DateTime <=> $a->DateTime } @temp ];
}

sub _build_SignatureRequired {
    my ($self) = @_;

    return $self->xml->findvalue('PackageServiceOptions/SignatureRequired/Code')
        || undef;
}


sub _build_ProductType {
    my ($self) = @_;
    
    return $self->build_code('ProductType');
}

sub _build_ReferenceNumber {
    my ($self) = @_;
    
    my @nodes = $self->xml->findnodes('ReferenceNumber');
    my $return = [];
    foreach my $node (@nodes) {
        push @$return,Business::UPS::Tracking::Element::ReferenceNumber->new(
            xml => $node,
        );
    }
    return $return;
 }

sub _build_TrackingNumber {
    my ($self) = @_;
    return $self->xml->findvalue('TrackingNumber');
}


sub _build_RescheduledDelivery {
    my ($self) = @_;

    my $datestr = $self->xml->findvalue('RescheduledDeliveryDate');
    my $date    = Business::UPS::Tracking::Utils::parse_date($datestr);

    my $timestr = $self->xml->findvalue('RescheduledDeliveryTime');
    $date = Business::UPS::Tracking::Utils::parse_time( $timestr, $date );

    return $date;
}




=head1 METHODS

=head2 CurrentStatus

Returns the last known status. Can return

=over

=item * In Transit

=item * Delivered

=item * Exeption

=item * Pickup

=item * Manifest Pickup

=item * Unknown

=back

If you need to obtain more detailed information on the current status use
C<$pakcage-E<gt>Activity-E<gt>[0]-<gt>StatusTypeDescription>,
C<$pakcage-E<gt>Activity-E<gt>[0]-<gt>StatusCode> and
C<$pakcage-E<gt>Activity-E<gt>[0]-<gt>DateTime>.

=cut

sub CurrentStatus {
    my ($self) = @_;
    
    my $activities = $self->Activity;
  
    if (defined $activities 
        && ref $activities eq 'ARRAY') {
        return $activities->[0]->Status;
    } else {
        return 'Unknown';
    }
}

=head2 meta

Moose meta method

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
