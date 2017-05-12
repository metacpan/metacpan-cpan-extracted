package Business::CyberSource::RequestPart::OtherTax;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with 'MooseX::RemoteHelper::CompositeSerialization';

use MooseX::Types::Common::Numeric qw( PositiveOrZeroNum );

has 'alternate_tax_amount' => (
    isa         => PositiveOrZeroNum,
    is          => 'ro',
    remote_name => 'alternateTaxAmount',
);

has 'alternate_tax_indicator' => (
    isa         => 'Bool',
    is          => 'ro',
    remote_name => 'alternateTaxIndicator',
    serializer => sub {
        my ( $attr, $instance ) = @_;

        return $attr->get_value( $instance ) ? '1' : '0';
    }
);

has 'vat_tax_amount' => (
    isa         => PositiveOrZeroNum,
    is          => 'ro',
    remote_name => 'vatTaxAmount',
);

has 'vat_tax_rate' => (
    isa         => PositiveOrZeroNum,
    is          => 'ro',
    remote_name => 'vatTaxRate',
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: OtherTax information

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::RequestPart::OtherTax - OtherTax information

=head1 VERSION

version 0.010008

=head1 EXTENDS

L<Business::CyberSource::MessagePart>

=head1 ATTRIBUTES

=head2 alternate_tax_amount

Amount of all taxes, excluding the local tax and national tax

=head2 alternate_tax_indicator

Flag that indicates whether the alternate tax amount is included in the request.

=head2 vat_tax_amount

Total amount of VAT or other tax on freight or shipping only

=head2 vat_tax_rate

Total amount of VAT or other tax on freight or shipping only

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
