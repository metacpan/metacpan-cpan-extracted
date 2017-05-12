package Business::CyberSource::Request::Capture;
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

use MooseX::Types::CyberSource qw( CaptureService );

has '+service' => (
    isa         => CaptureService,
    remote_name => 'ccCaptureService',
    lazy_build  => 0,
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: CyberSource Capture Request Object

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Request::Capture - CyberSource Capture Request Object

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Business::CyberSource::Request::Capture;

	my $capture = Business::CyberSource::Request::Capture->new({
		reference_code => 'merchant reference code',
		service => {
			request_id => 'authorization response request_id',
		},
		purchase_totals => {
			total    => 5.01,  # same amount as in authorization
			currency => 'USD', # same currency as in authorization
                        discount => 0.50,  # optional
                        duty     => 0.07,  # optional
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
        invoice_header => {
            purchaser_vat_registration_number => 'ATU99999999',
            user_po => '123456',
            vat_invoice_reference_number => '1234',
        },
        other_tax => {
            alternate_tax_amount => '00.10',
            alternate_tax_indicator => 1,
            vat_tax_amount => '0.10',
            vat_tax_rate => '0.10',
        },
	});

=head1 DESCRIPTION

This object allows you to create a request for a capture.

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
