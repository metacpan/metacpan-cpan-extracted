package Business::CyberSource::ResponsePart::TaxReply::Item;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';

has id => (
	isa         => 'Int',
	remote_name => 'id',
	is          => 'ro',
);

has city_tax_amount => (
	isa         => 'Num',
	remote_name => 'cityTaxAmount',
	is          => 'ro',
);

has county_tax_amount => (
	isa         => 'Num',
	remote_name => 'countyTaxAmount',
	is          => 'ro',
);

has district_tax_amount => (
	isa         => 'Num',
	remote_name => 'districtTaxAmount',
	is          => 'ro',
);

has state_tax_amount => (
	isa         => 'Num',
	remote_name => 'stateTaxAmount',
	is          => 'ro',
);

has total_tax_amount => (
	isa         => 'Num',
	remote_name => 'totalTaxAmount',
	is          => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: taxReply_item

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::ResponsePart::TaxReply::Item - taxReply_item

=head1 VERSION

version 0.010008

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
