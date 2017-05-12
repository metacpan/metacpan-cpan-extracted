package Business::CyberSource::Request::Credit;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::Request';
with qw(
	Business::CyberSource::Request::Role::DCC
	Business::CyberSource::Request::Role::TaxService
);

use MooseX::Types::CyberSource qw( BillTo Card CreditService );

use Module::Runtime qw( use_module );

sub _build_service {
	use_module('Business::CyberSource::RequestPart::Service::Credit');
	return Business::CyberSource::RequestPart::Service::Credit->new;
}

has '+service' => (
	isa         => CreditService,
	remote_name => 'ccCreditService'
);

has bill_to => (
	isa         => BillTo,
	remote_name => 'billTo',
	traits      => ['SetOnce'],
	is          => 'rw',
	coerce      => 1,
);

has card => (
	isa         => Card,
	remote_name => 'card',
	traits      => ['SetOnce'],
	is          => 'rw',
	coerce      => 1,
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: CyberSource Credit Request Object

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Request::Credit - CyberSource Credit Request Object

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Business::CyberSource::Request::Credit;

	my $req = Business::CyberSource::Request::Credit->new({
			reference_code => 'merchant reference code',
			bill_to => {
				first_name  => 'Caleb',
				last_name   => 'Cushing',
				street      => 'somewhere',
				city        => 'Houston',
				state       => 'TX',
				postal_code => '77064',
				country     => 'US',
				email       => 'xenoterracide@gmail.com',
			},
			purchase_totals => {
				total    => 5.00,
				discount => 0.50, # optional
				duty     => 0.01, # optional
				currency => 'USD',
			},
			card => {
				account_number => '4111-1111-1111-1111',
				expiration => {
					month => '09',
					year => '2025',
				},
			},
            invoice_header => {
                purchaser_vat_registration_number => 'ATU99999999',
                user_po => '123456',
                vat_invoice_reference_number => '1234',
            },
            other_tax => {
                alternate_tax_amount => '0.10',
                alternate_tax_indicator => 1,
                vat_tax_amount => '0.10',
                vat_tax_rate => '0.10',
            },
		});

=head1 DESCRIPTION

This object allows you to create a request for a credit. You can use
L<Business::CyberSource::Request::StandAloneCredit> or the
L<Business::CyberSource::Request::FollowOnCredit> if you want your objects to
be checked for all required fields.

=head1 EXTENDS

L<Business::CyberSource::Request>

=head1 WITH

=over

=item L<Business::CyberSource::Request::Role::DCC>

=back

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
