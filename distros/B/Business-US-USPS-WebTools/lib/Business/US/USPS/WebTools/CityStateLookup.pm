use v5.10;
use utf8;

package Business::US::USPS::WebTools::CityStateLookup;
use strict;
no warnings 'uninitialized';

use parent qw(Business::US::USPS::WebTools);

use subs qw();
use vars qw($VERSION);

$VERSION = '1.125';

=encoding utf8

=head1 NAME

Business::US::USPS::WebTools::CityStateLookup - lookup a City and State by Zip Code

=head1 SYNOPSIS

	use Business::US::USPS::WebTools::AddressStandardization;

	my $looker_upper = Business::US::USPS::WebTools::CityStateLookup->new( {
		UserID   => $ENV{USPS_WEBTOOLS_USERID},
		Password => $ENV{USPS_WEBTOOLS_PASSWORD},
		Testing  => 1,
		} );

	my $hash = $looker_upper->lookup_city_state(
		);

	if( $looker_upper->is_error )
		{
		warn "Oh No! $looker_upper->{error}{description}\n";
		}
	else
		{
		print join "\n", map { "$_: $hash->{$_}" }
			qw(FirmName Address1 Address2 City State Zip5 Zip4);
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

=item lookup_city_state( KEY, VALUE, ... )

The C<verify_address> method takes the following keys, which come
directly from the USPS web service interface:

	FirmName	The name of the company
	Address1	The suite or apartment
	Address2	The street address
	City		The name of the city
	State		The two letter state abbreviation
	Zip5		The 5 digit zip code
	Zip4		The 4 digit extension to the zip code

It returns an anonymous hash with the same keys, but the values are
the USPS's canonicalized address. If there is an error, the hash values
will be the empty string, and the error flag is set. Check is with C<is_error>:

	$verifier->is_error;

See the C<is_error> documentation in Business::US::USPS::WebTools for more
details on error information.

=cut

sub lookup_city_state {
	my( $self, $zip_code ) = @_;

	$self->_make_url( { Zip5 => $zip_code } );

	$self->_make_request;

	$self->_parse_response;
	}


sub _api_name { "CityStateLookup" }

sub _make_query_xml {
	my( $self, $hash ) = @_;

	my $user = $self->userid;
	my $pass = $self->password;

	my $xml =
		qq|<CityStateLookupRequest USERID="$user" PASSWORD="$pass">|  .
		qq|<ZipCode ID="0"><Zip5>$$hash{Zip5}</Zip5>| .
		qq|</ZipCode></CityStateLookupRequest>|;

	}

sub _parse_response {
	my( $self ) = @_;
	#require 'Hash::AsObject';

	my %hash = ();
	foreach my $field ( $self->_fields ) {
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

Copyright © 2020, Steve Simms. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
