use v5.10;
use utf8;

package Business::US::USPS::WebTools::AddressStandardization;
use strict;
no warnings 'uninitialized';

use parent qw(Business::US::USPS::WebTools);

use subs qw();
use vars qw($VERSION);

$VERSION = '1.125';

=encoding utf8

=head1 NAME

Business::US::USPS::WebTools::AddressStandardization - canonicalize a US address

=head1 SYNOPSIS

	use Business::US::USPS::WebTools::AddressStandardization;

	my $verifier = Business::US::USPS::WebTools::AddressStandardization->new( {
		UserID   => $ENV{USPS_WEBTOOLS_USERID},
		Password => $ENV{USPS_WEBTOOLS_PASSWORD},
		Testing  => 1,
		} );

	my $hash = $verifier->verify_address(
		FirmName => '',
		Address1 => '',
		Address2 => '6406 Ivy Lane',
		City     => 'Greenbelt',
		State    => 'MD',
		Zip5     => '',
		Zip4     => '',
		);

	if( $verifier->is_error )
		{
		warn "Oh No! $verifier->{error}{description}\n";
		}
	else
		{
		print join "\n", map { "$_: $hash->{$_}" }
			qw(FirmName Address1 Address2 City State Zip5 Zip4 DeliveryPoint CarrierRoute ReturnText);
		}


=head1 DESCRIPTION

*** THIS IS ALPHA SOFTWARE ***

This module implements the Address Standardization web service from the
US Postal Service. It is a subclass of Business::US::USPS::WebTools.

=cut

=over 4

=cut

sub _fields   { qw( FirmName Address1 Address2 City State Zip5 Zip4 ) }
sub _required { qw( Address2 City State ) }
sub _response { (_fields(), qw( DeliveryPoint CarrierRoute ReturnText )) }

=item verify_address( KEY, VALUE, ... )

The C<verify_address> method takes the following keys, which come
directly from the USPS web service interface:

	FirmName	The name of the company
	Address1	The suite or apartment
	Address2	The street address
	City		The name of the city
	State		The two letter state abbreviation
	Zip5		The 5 digit ZIP code
	Zip4		The 4 digit extension to the ZIP code

It returns an anonymous hash with the same keys, but the values are
the USPS's canonicalized address, plus three additional keys:

	DeliveryPoint	The 2 digit extension to the ZIP+4 code
	CarrierRoute	The 4 character postal carrier route
	ReturnText	An error message when multiple addresses are found

If there is an error, the hash values will be the empty string, and
the error flag is set. Check is with C<is_error>:

	$verifier->is_error;

See the C<is_error> documentation in Business::US::USPS::WebTools for more
details on error information.

=cut

sub verify_address {
	my( $self, %hash ) = @_;

	$self->_make_url( \%hash );

	$self->_make_request;

	$self->_parse_response;
	}


sub _api_name { "Verify" }

sub _make_query_xml {
	my( $self, $hash ) = @_;

	my $user = $self->userid;
	my $pass = $self->password;

	my $xml =
		qq|<AddressValidateRequest USERID="$user" PASSWORD="$pass">|  .
		qq|<IncludeOptionalElements>true</IncludeOptionalElements>|  .
		qq|<ReturnCarrierRoute>true</ReturnCarrierRoute>|  .
		qq|<Address ID="0">|;

	foreach my $field ( $self->_fields ) {
		$xml .= "<$field>$$hash{$field}</$field>";
		}

	$xml .= qq|</Address></AddressValidateRequest>|;

	return $xml;
	}

sub _parse_response {
	my( $self ) = @_;
	#require 'Hash::AsObject';

	my %hash = ();
	foreach my $field ( $self->_response ) {
		my( $value ) = $self->response =~ m|<$field>(.*?)</$field>|g;

		$hash{$field} = $value || '';
		}

	bless \%hash, ref $self; # 'Hash::AsObject';
	}

=back

=head1 TO DO

=head1 SEE ALSO

L<Business::US::USPS::WebTools>

The WebTools API is documented on the US Postal Service's website:

	https://www.usps.com/business/web-tools-apis/address-information-api.pdf

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/ssimms/business-us-usps-webtools

=head1 AUTHOR

brian d foy

=head1 MAINTAINER

Steve Simms

=head1 COPYRIGHT AND LICENSE

Copyright © Steve Simms. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
