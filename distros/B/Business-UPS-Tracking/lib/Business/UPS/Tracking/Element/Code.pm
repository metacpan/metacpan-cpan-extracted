# ============================================================================
package Business::UPS::Tracking::Element::Code;
# ============================================================================
use utf8;
use 5.0100;

use Moose;

use Business::UPS::Tracking::Utils;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Element::Code - Generic container for parameters
  
=head1 DESCRIPTION

This is a generic container class used to store information constisting
of a code and a description

=head1 ACCESSORS

=head2 xml

Original L<XML::LibXML::Node> node.

=head2 meta

Moose meta method

=head2 Code

Alphanumeric code

=head2 Description

Description string

=cut

has 'xml' => (
    is       => 'rw',
    isa      => 'XML::LibXML::Node',
    required => 1,
    trigger  => \&_build_code,
);
has 'Code' => (
    is  => 'rw',
    isa => 'Str',
);
has 'Description' => (
    is  => 'rw',
    isa => 'Str',
);

sub _build_code {
    my ( $self, $xml ) = @_;

    $self->Code($xml->findvalue('Code'));
    $self->Description($xml->findvalue('Description'));

    return;
}

sub serialize {
    my ($self) = @_;
    
    if ($self->Description) {
        return $self->Description.' ('.$self->Code.')';
    } else {
        return $self->Code;
    }
    
}

=head1 METHODS

=head2 printall 

Returns the serialized object content

=head2 meta

Moose meta method

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
