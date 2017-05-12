package Business::CyberSource::ResponsePart::TaxReply;
use strict;
use warnings;
use namespace::autoclean;
use Module::Runtime  qw( use_module );

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with qw(
	Business::CyberSource::Response::Role::ReasonCode
);
use MooseX::Types::CyberSource qw( TaxReplyItems );

has items => (
	isa         => TaxReplyItems,
	remote_name => 'item',
	is          => 'bare',
	coerce      => 1,
);

has city => (
	isa         => 'Str',
	remote_name => 'city',
	is          => 'ro',
);

has total => (
	isa         => 'Num',
	remote_name => 'grandTotalAmount',
	is          => 'ro',
);

has postal_code => (
	isa         => 'Str',
	remote_name => 'postalCode',
	is          => 'ro',
);

has state => (
	isa         => 'Str',
	remote_name => 'state',
	is          => 'ro',
);

has total_city_tax_amount => (
	isa         => 'Num',
	remote_name => 'totalCityTaxAmount',
	is          => 'ro',
);

has total_county_tax_amount => (
	isa         => 'Num',
	remote_name => 'totalCountyTaxAmount',
	is          => 'ro',
);

has total_district_tax_amount => (
	isa         => 'Num',
	remote_name => 'totalDistrictTaxAmount',
	is          => 'ro',
);

has total_state_tax_amount => (
	isa         => 'Num',
	remote_name => 'totalStateTaxAmount',
	is          => 'ro',
);

has total_tax_amount => (
	isa         => 'Num',
	remote_name => 'totalTaxAmount',
	is          => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Reply section for Tax Service

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::ResponsePart::TaxReply - Reply section for Tax Service

=head1 VERSION

version 0.010008

=head1 ATTRIBUTES

=head2 items

=head2 city

=head2 total

=head2 postal_code

=head2 state

=head2 total_city_tax_amount

=head2 total_county_tax_amount

=head2 total_district_tax_amount

=head2 total_state_tax_amount

=head2 total_tax_amount

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
