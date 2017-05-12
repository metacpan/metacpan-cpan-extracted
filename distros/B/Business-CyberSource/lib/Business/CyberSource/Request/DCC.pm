package Business::CyberSource::Request::DCC;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::Request';
with qw(
	Business::CyberSource::Request::Role::CreditCardInfo
	Business::CyberSource::Role::ForeignCurrency
	Business::CyberSource::Request::Role::TaxService
);

has '+service' => ( remote_name => 'ccDCCService' );

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: CyberSource DCC Request Object

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Request::DCC - CyberSource DCC Request Object

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Business::CyberSource::Request::DCC;

	my $dcc
		= Business::CyberSource::Request::DCC->new({
			reference_code => '1984',
			purchase_totals => {
				currency       => 'USD',
				total          => '1.00',
				foreign_currency => 'EUR',
			},
			card => {
				credit_card    => '5100870000000004',
				expiration => {
					month => '04',
					year  => '2012',
				},
			},
		});

=head1 DESCRIPTION

This object allows you to create a request for Direct Currency Conversion.

=head1 EXTENDS

L<Business::CyberSource::Request>

=head1 WITH

=over

=item L<Business::CyberSource::Request::Role::CreditCardInfo>

=item L<Business::CyberSource::Role::ForeignCurrency>

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
