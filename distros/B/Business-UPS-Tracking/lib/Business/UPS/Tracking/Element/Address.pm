# ============================================================================
package Business::UPS::Tracking::Element::Address;
# ============================================================================
use utf8;
use 5.0100;

use Moose;

use Business::UPS::Tracking::Utils;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Element::Address - An address
  
=head1 DESCRIPTION

This class represents an address. Usually it is created 
automatically from a L<Business::UPS::Tracking::Shipment> object.

=head1 ACCESSORS

=head2 xml

Original L<XML::LibXML::Node> node.

=head2 AddressLine1

=head2 AddressLine2

=head2 AddressLine3

=head2 City

=head2 StateProviceCode

Only US and Canada

=head2 PostalCode

=head2 CountryCode

ISO 3166-1 alpha-2 country code.

=cut

has 'xml' => (
    is       => 'rw',
    isa      => 'XML::LibXML::Node',
    required => 1,
    trigger  => \&_build_address,
);
has 'AddressLine1' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);
has 'AddressLine2' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);
has 'AddressLine3' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);
has 'City' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);
has 'StateProvinceCode' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);
has 'PostalCode' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);
has 'CountryCode' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

sub _build_address {
    my ( $self, $xml ) = @_;

    foreach my $node ( @{ $xml->childNodes } ) {
        my $name  = $node->nodeName;
        my $value = $node->textContent;
        next unless $self->can($name);
        next unless defined $value;
        $self->$name($value);
    }

    return;
}

=head1 METHODS

=head2 printall 

Serialize address into a string.

=head2 meta

Moose meta method

=cut

sub printall {
    my ($self) = @_;
    
    my @address;
    push (@address,$self->AddressLine1)
        if $self->AddressLine1;
    push (@address,$self->AddressLine2)
        if $self->AddressLine2;
    push (@address,$self->AddressLine3)
        if $self->AddressLine3;
    
    my $line = $self->CountryCode;
    $line .= '-'.$self->PostalCode
        if $self->PostalCode;
    $line .= ' '.$self->City
        if $self->City;
        
    push (@address,$line);
    
    return join("\n",@address);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
