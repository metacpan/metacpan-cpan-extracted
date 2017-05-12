# ============================================================================
package Business::UPS::Tracking::Element::Weight;
# ============================================================================
use utf8;
use 5.0100;

use Moose;

use Business::UPS::Tracking::Utils;
use Business::UPS::Tracking::Element::Code;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Element::Weight - A shipment or package weight
  
=head1 DESCRIPTION

This class represents a declaration of weight. Usually it is created 
automatically from a L<Business::UPS::Tracking::Shipment> object. 

This module uses overload for stringification if called in string context.

=head1 ACCESSORS

=head2 xml

Original L<XML::LibXML::Node> node.

=head2 UnitOfMeasurement

Unit of measurement. 
Returns a L<Business::UPS::Tracking::Element::Code> object.

=head2 Weight

Weight value (e.g. '5.50')

=cut

has 'xml' => (
    is       => 'rw',
    isa      => 'XML::LibXML::Node',
    required => 1,
    trigger  => \&_build_weight,
);
has 'UnitOfMeasurement'=> (
    is      => 'rw',
    isa     => 'Business::UPS::Tracking::Element::Code',
    lazy_build  => 1,
);
has 'Weight'=> (
    is      => 'rw',
    isa     => 'Num',
);

sub _build_weight {
    my ($self,$xml) = @_;
    
    my $unit = Business::UPS::Tracking::Element::Code->new(
        xml => $xml->findnodes('UnitOfMeasurement')->get_node(1)
    );

    $self->UnitOfMeasurement($unit);
    $self->Weight($xml->findvalue('Weight'));
    
    return;
}

sub serialize {
    my ($self) = @_;
    
    return $self->printall;
}

=head1 METHODS

=head2 printall

Returns the weight as a string (eg. '14.5 KGS')

=head2 meta

Moose meta method

=cut

sub printall {
    my ($self) = @_;
    return $self->Weight.' '.$self->UnitOfMeasurement->Code;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
