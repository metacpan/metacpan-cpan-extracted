package Business::CyberSource::Request::Authorization;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::Request';
with qw(
	Business::CyberSource::Request::Role::BillingInfo
	Business::CyberSource::Request::Role::CreditCardInfo
	Business::CyberSource::Request::Role::DCC
	Business::CyberSource::Request::Role::TaxService
);

use MooseX::Types::CyberSource qw( BusinessRules AuthService );

use Module::Runtime qw( use_module );

has '+service' => (
    remote_name => 'ccAuthService',
    isa         => AuthService,
    lazy_build  => 0,
);

sub _build_service {
	use_module('Business::CyberSource::RequestPart::Service::Auth');
	return Business::CyberSource::RequestPart::Service::Auth->new;
}

has business_rules => (
	isa         => BusinessRules,
	remote_name => 'businessRules',
	traits      => ['SetOnce'],
	is          => 'rw',
	coerce      => 1,
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: CyberSource Authorization Request object

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Request::Authorization - CyberSource Authorization Request object

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Business::CyberSource::Request::Authorization;

	Business::CyberSource::Request::Authorization->new({
		reference_code => '42',
		bill_to => {
			first_name  => 'Caleb',
			last_name   => 'Cushing',
			street      => '100 somewhere st',
			city        => 'Houston',
			state       => 'TX',
			postal_code => '77064',
			country     => 'US',
			email       => 'xenoterracide@gmail.com',
		},
		purchase_totals => {
			currency => 'USD',
			total    => 5.00,
			discount => 0.50, # optional
			duty     => 0.03, # optional
		},
		card => {
			account_number => '4111111111111111',
			expiration => {
				month => 9,
				year  => 2025,
			},
		},
		# optional:
		ship_to => {
			country     => 'US',
			postal_code => '78701',
			city        => 'Austin',
			state       => 'TX',
			street1     => '306 E 6th',
			street2     => 'Dizzy Rooster',
		},
	});

=head1 DESCRIPTION

Offline authorization means that when you submit an order using a credit card,
you will not know if the funds are available until you capture the order and
receive confirmation of payment. You typically will not ship the goods until
you receive this payment confirmation. For offline credit cards, it will take
typically five days longer to receive payment confirmation than for online
cards.

=head1 EXTENDS

L<Business::CyberSource::Request>

=head1 WITH

=over

=item L<Business::CyberSource::Request::Role::BillingInfo>

=item L<Business::CyberSource::Request::Role::CreditCardInfo>

=item L<Business::CyberSource::Request::Role::DCC>

=item L<Business::CyberSource::Request::Role::TaxService>

=back

=head1 ATTRIBUTES

=head2 references_code

Merchant Reference Code

=head2 bill_to

L<Business::CyberSource::RequestPart::BillTo>

=head2 ship_to

L<Business::CyberSource::RequestPart::ShipTo>

=head2 purchase_totals

L<Business::CyberSource::RequestPart::PurchaseTotals>

=head2 card

L<Business::CyberSource::RequestPart::Card>

=head2 business_rules

L<Business::CyberSource::RequestPart::BusinessRules>

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
