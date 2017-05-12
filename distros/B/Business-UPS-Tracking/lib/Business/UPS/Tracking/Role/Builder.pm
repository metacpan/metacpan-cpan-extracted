# ============================================================================
package Business::UPS::Tracking::Role::Builder;
# ============================================================================
use utf8;
use 5.0100;

use Moose::Role;
#requires('xml');

use Business::UPS::Tracking::Element::Address;
use Business::UPS::Tracking::Element::Weight;
use Business::UPS::Tracking::Element::ReferenceNumber;
use Business::UPS::Tracking::Element::Code;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Role::Builder - Helper role
  
=head1 DESCRIPTION

This role provides methods that construct various objects (eg. 
Business::UPS::Tracking::Element::Address).

=head1 METHODS

=head3 build_address

 my $address = $self->build_address($xpath_expression);

Turns an address xml node into a L<Business::UPS::Tracking::Element::Address> 
object.

=cut

sub build_address {
    my ($self,$xpath) = @_;
    
    my $node = $self->xml->findnodes($xpath)->get_node(1);
    
    return 
        unless $node && ref $node;
        
    return Business::UPS::Tracking::Element::Address->new(
        xml => $node,
    );
}

=head3 build_code

 my $address = $self->build_code($xpath_expression);

Turns an address xml node into a L<Business::UPS::Tracking::Element::Address> 
object.

=cut


sub build_code {
    my ($self,$xpath) = @_;
    
    my $node = $self->xml->findnodes($xpath)->get_node(1);
    
    return 
        unless $node && ref $node;
        
    return Business::UPS::Tracking::Element::Code->new(
        xml => $node,
    );
}

=head3 build_weight

 my $weight = $self->build_weight($xpath_expression);

Turns an weight xml node into a L<Business::UPS::Tracking::Element::Weight> 
object.

=cut

sub build_weight {
    my ($self,$xpath) = @_;
    
    my $node = $self->xml->findnodes($xpath)->get_node(1);
    
    return 
        unless $node && ref $node;
        
    return Business::UPS::Tracking::Element::Weight->new(
        xml => $node,
    );
}

=head3 build_referencenumber

 my $weight = $self->build_referencenumber($xpath_expression);

Turns an weight xml node into a 
L<Business::UPS::Tracking::Element::ReferenceNumber> object.

=cut

sub build_referencenumber {
    my ($self,$xpath) = @_;
    
    my $node = $self->xml->findnodes($xpath)->get_node(1);
    
    return 
        unless $node && ref $node;
        
    return Business::UPS::Tracking::Element::ReferenceNumber->new(
        xml => $node,
    );
}

no Moose::Role;
1;
