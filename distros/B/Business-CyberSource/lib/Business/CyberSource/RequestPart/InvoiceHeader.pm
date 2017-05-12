package Business::CyberSource::RequestPart::InvoiceHeader;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with 'MooseX::RemoteHelper::CompositeSerialization';

use MooseX::Types::Common::String qw( NonEmptySimpleStr );

has 'purchaser_vat_registration_number' => (
    isa         => NonEmptySimpleStr,
    is          => 'ro',
    remote_name => 'purchaserVATRegistrationNumber',
);

has 'user_po' => (
    isa         => NonEmptySimpleStr,
    is          => 'ro',
    remote_name => 'userPO',
);

has 'vat_invoice_reference_number' => (
    isa         => NonEmptySimpleStr,
    is          => 'ro',
    remote_name => 'vatInvoiceReferenceNumber',
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: InvoiceHeader information

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::RequestPart::InvoiceHeader - InvoiceHeader information

=head1 VERSION

version 0.010008

=head1 EXTENDS

L<Business::CyberSource::MessagePart>

=head1 ATTRIBUTES

=head2 purchaser_vat_registration_number

Identification number assigned to the purchasing company by the tax
authorities .

=head2 user_po

Value used by your customer to identify the order. This value is typically a purchase order number.

=head2 vat_invoice_reference_number

VAT invoice number associated with the transaction.

=for Pod::Coverage BUILD

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
