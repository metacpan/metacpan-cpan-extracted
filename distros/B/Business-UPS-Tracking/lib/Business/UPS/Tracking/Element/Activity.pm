# ============================================================================
package Business::UPS::Tracking::Element::Activity;
# ============================================================================
use utf8;
use 5.0100;

use Moose;
with qw(Business::UPS::Tracking::Role::Print
    Business::UPS::Tracking::Role::Builder);

no if $] >= 5.017004, warnings => qw(experimental::smartmatch);

use Business::UPS::Tracking::Utils;
use Business::UPS::Tracking::Element::Activity;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Element::Activity - A small freight package activity
  
=head1 DESCRIPTION

This class represents an small freight package activity. Usually it is created 
automatically from a L<Business::UPS::Tracking::Element::Package> object.

=head1 ACCESSORS

=head2 xml

Original L<XML::LibXML::Node> node.

=head2 ActivityLocationAddress

A L<Business::UPS::Tracking::Element::Address> object representing the 
location of the activity.

=head2 ActivityLocation

Type of location. 
Returns a L<Business::UPS::Tracking::Element::Code> object.

=head2 SignedForByName

=head2 StatusCode

=head2 StatusType

Status code.
Returns a L<Business::UPS::Tracking::Element::Code> object.

=head2 DateTime

L<DateTime> object.

=cut

has 'xml' => (
    is       => 'ro',
    isa      => 'XML::LibXML::Node',
    required => 1,
);

has 'ActivityLocationAddress' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Element::Address]',
    traits  => ['Printable'],
    documentation   => 'Address',
    lazy_build      => 1,
);
has 'ActivityLocation' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Element::Code]',
    traits  => ['Printable'],
    lazy_build      => 1,
);
has 'SignedForByName' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    traits  => ['Printable'],
    lazy_build      => 1,
    documentation   => 'Signed by',
);
has 'StatusCode' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy_build      => 1,
    traits  => ['Printable'],
    documentation   => 'Satus code',
);
# MP ... Billing information
# OR ... Original scan
# DP ... Departure scan
# AR ... Arival scan
# LC ... Location scan
# KS/KR ... Annahmeverweigerung
# KM/KB ... Anlieferung (Bounce?)
# 48 ... Failed 1st atempt
# KX ... Failed 2nd atempt
# 49 ... Failed 3rd atempt
# UL ... Unload scan

has 'StatusType' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Element::Code]',
    traits  => ['Printable'],
    lazy_build      => 1,
    documentation   => 'Status',
);
has 'DateTime' => (
    is      => 'ro',
    isa     => 'Maybe[Business::UPS::Tracking::Type::Date]',
    traits  => ['Printable'],
    lazy_build      => 1,
    documentation   => 'Date/time',
);

sub _build_DateTime {
    my ($self) = @_;

    my $datestr = $self->xml->findvalue('Date');
    my $date    = Business::UPS::Tracking::Utils::parse_date($datestr);

    my $timestr = $self->xml->findvalue('Time');
    return Business::UPS::Tracking::Utils::parse_time( $timestr, $date );
}

sub _build_StatusType {
    my ($self) = @_;
    
    return $self->build_code('Status/StatusType');
}

sub _build_StatusCode {
    my ($self) = @_;

    return $self->xml->findvalue('Status/StatusCode/Code');
}

sub _build_ActivityLocationAddress {
    my ($self) = @_;

    return $self->build_address('ActivityLocation/Address' );
}

sub _build_ActivityLocation {
    my ($self) = @_;
    
    return $self->build_code('ActivityLocation' );
}

sub _build_SignedForByName {
    my ($self) = @_;

    return $self->xml->findvalue('ActivityLocation/SignedForByName');
}

=head1 METHODS

=head2 Status

Translates the L<StatusTypeCode> to a short description. Can return

=over

=item * In Transit

=item * Delivered

=item * Exeption

=item * Pickup

=item * Manifest Pickup

=item * Unknown

=back

=cut

sub Status {
    my ($self) = @_;
    
    given ($self->StatusType->Code) {
        when ('I') {
            return 'In Transit';
        }
        when ('D') {
            return 'Delivered';
        }
        when ('X') {
            return 'Exeption';
        }
        when ('P') {
            return 'Pickup';
        }
        when ('M') {
            return 'Manifest Pickup';
        }
        default {
            return 'Unknown';
        }
    }
}

=head2 meta

Moose meta method

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
