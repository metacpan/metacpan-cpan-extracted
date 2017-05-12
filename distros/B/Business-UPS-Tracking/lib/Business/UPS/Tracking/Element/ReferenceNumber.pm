# ============================================================================
package Business::UPS::Tracking::Element::ReferenceNumber;
# ============================================================================
use utf8;
use 5.0100;

use Moose;

use Business::UPS::Tracking::Utils;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Element::ReferenceNumber - A reference number
  
=head1 DESCRIPTION

This class represents a reference number. Usually it is created 
automatically from a L<Business::UPS::Tracking::Shipment> object.

=head1 ACCESSORS

=head2 xml

Original L<XML::LibXML::Node> node.

=head2 Code

Reference number types. 

For small package available options are:

=over 3

=item * 28 - Purchase Order No.

=item * 33 - Model Number

=item * 34 - Part Number

=item * 35 - Serial Number

=item * 50 - Department Number

=item * 51 - Store Number

=item * 54 - FDA Product Code

=item * 55 - Acct. Rec. Customer Acct.

=item * 56 - Appropriation Number

=item * 57 - Bill of Lading Number

=item * 59 - Invoice Number

=item * 60 - Manifest Key Number

=item * 61-  Dealer Order Number

=item * 62 - Production Code

=item * 63 - Purchase Req. Number

=item * 64 - Salesperson Number

=item * 67 - Transaction Ref. No.

=item * RZ - RMA

=item * 9V - COD Number

=back

For freight available options are:

=over 3

=item * BL

=item * PO

=back

=head2 Value

Reference number as supplied by the customer

=cut

has 'xml' => (
    is       => 'rw',
    isa      => 'XML::LibXML::Node',
    required => 1,
    trigger  => \&_build_referencenumber,
);
has 'Code' => (
    is  => 'rw',
    isa => 'Str',
);
has 'Value' => (
    is  => 'rw',
    isa => 'Str',
);

our %DESCRIPTION = (
    '28' => 'Purchase Order No.',
    '33' => 'Model Number',
    '34' => 'Part Number',
    '35' => 'Serial Number',
    '50' => 'Department Number',
    '51' => 'Store Number',
    '54' => 'FDA Product Code',
    '55' => 'Acct. Rec. Customer Acct.',
    '56' => 'Appropriation Number',
    '57' => 'Bill of Lading Number',
    '59' => 'Invoice Number',
    '60' => 'Manifest Key Number',
    '61' => 'Dealer Order Number',
    '62' => 'Production Code',
    '63' => 'Purchase Req. Number',
    '64' => 'Salesperson Number',
    '67' => 'Transaction Ref. No.',
    'RZ' => 'RMA',
    '9V' => 'COD Number',
    'BL' => 'BL',
    'PO' => 'PO',
);


sub _build_referencenumber {
    my ( $self, $xml ) = @_;

    $self->Code( $xml->findvalue('Code') );
    $self->Value( $xml->findvalue('Value') );
    
    return;
}

=head1 METHODS

=head2 printall 

Returns the serialized object content

=cut

sub printall {
    my ($self) = @_;
    return $self->Value;
}

=head2 Description

Returns the description for the current reference number code.

=cut

sub Description {
    my ($self) = @_;
    my $code = $self->Code;
    return $DESCRIPTION{$code}
        if (exists $DESCRIPTION{$code});
    return 'Unspecified';
}

sub serialize {
    my ($self) = @_;
    
    return $self->Value;
}

=head2 meta

Moose meta method

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
