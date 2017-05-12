package Business::Tax::Avalara;

use 5.010;

use strict;
use warnings;

use Try::Tiny;
use Carp;
use LWP;
use HTTP::Request::Common;
use Encode qw();
use Data::Dump;
use JSON::PP;


=head1 NAME

Business::Tax::Avalara - An interface to Avalara's REST webservice

=head1 SYNOPSYS

	use Business::Tax::Avalara;
	my $avalara_gateway = Business::Tax::Avalara->new(
		customer_code  => $customer_code,
		company_code   => $company_code,
		user_name      => $user_name,
		password       => $password,
		origin_address =>
		{
			line_1      => '1313 Mockingbird Lane',
			postal_code => '98765',
		},
	);
	
	my $tax_results = $avalara_gateway->get_tax(
		destination_address =>
		{
			line_1      => '42 Evergreen Terrace',
			city        => 'Springfield',
			postal_code => '12345',
		},
		cart_lines =>
		[
			{
				sku      => '42ACE',
				quantity => 1,
				amount   => '8.99',
			},
			{
				sku      => '9FCE2',
				quantity => 2,
				amount   => '38.98',
			}
		],
		
	);
	

=head1 DESCRIPTION

Business::Tax::Avalara is a simple interface to Avalara's REST-based sales tax webservice.
It takes in a perl hash of data to send to Avalara, generates the JSON, fetches a response,
and converts that back into a perl hash structure.

This module only supports the 'get_tax' method at the moment.

=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';
our $AVALARA_REQUEST_SERVER = 'avatax.avalara.net';
our $AVALARA_DEVELOPMENT_REQUEST_SERVER = 'development.avalara.net';

	
=head1 FUNCTIONS

=head2 new()

Creates a new Business::Tax::Avalara object with various options that do not change
between requests.

	my $avalara_gateway = Business::Tax::Avalara->new(
		customer_code   => $customer_code,
		company_code    => $company_code,
		user_name       => $user_name
		pasword         => $password,
		is_development  => boolean (optional), default 0
		origin_address  => $origin_address (optional),
		memcached       => A Cache::Memcached or Cache::Memcached::Fast object.
		request_timeout => Request timeout in seconds. Default is 3.
		debug           => 0,
	);
	
The fields customer_code, company_code, user_name, and password should be
provided by your Avalara representative. Account number and License key
are synonyms for user_name and password, respectively.

is_development should be set to 1 to use the development URL, and 0 for
production uses.

origin_address can either be set here, or passed into get_tax, depending on if
it changes per request, or if you're always shipping from the same location.
It is a hash ref, see below for formatting details.

If a memcached object is passed in, we can use this so that we don't send the same
request over in a certain period of time. This combines below with 'cache_timespan'
and 'unique_key' in the get_tax() call.

If debug is set to a true value, it will dump out the raw json messages being sent to
and coming back from Avalara.

Returns a Business::Tax::Avalara object.

=cut

sub new
{
	my ( $class, %args ) = @_;
	
	my @required_fields = qw( customer_code company_code user_name password );
	foreach my $required_field ( @required_fields )
	{
		if ( !defined $args{ $required_field } )
		{
			croak "Could not instantiate Business::Tax::Avalara module: Required field >$required_field< is missing.";
		}
	}
	
	my $self = {
		customer_code   => $args{'customer_code'},
		company_code    => $args{'company_code'},
		is_development  => $args{'is_development'} // 0,
		user_name       => $args{'user_name'},
		password        => $args{'password'},
		origin_address  => $args{'origin_address'},
		request_timeout => $args{'request_timeout'} // 3,
		debug           => $args{'debug'} // 0,
	};
	
	bless $self, $class;
	return $self;
}


=head2 get_tax()

Makes a JSON request using the 'get_tax' method, parses the response, and returns a perl hash.

	my $tax_results = $avalara_gateway->get_tax(
		destination_address   => $address_hash,
		origin_address        => $address_hash (may be specified in new),
		document_date         => $date (optional), default is current date
		cart_lines            => $cart_line_hash,
		customer_usage_type   => $customer_usage_type (optional),
		discount              => $order_level_discount (optional),
		purchase_order_number => $purchase_order_number (optional),
		exemption_number      => $exemption_number (optional),
		detail_level          => $detail_level (optional), default 'Tax',
		document_type         => $document_type (optional), default 'SalesOrder'
		document_code         => $document_code (optional), a unique identifier
		payment_date          => $date (optional),
		reference_code        => $reference_code (optional),
		commit                => 1|0, # Default 0, whether this is a 'final' query.
		unique_key            => A unique key for memcache (optional, see below)
		cache_timespan        => The number of seconds to cache results (see below),
		currency_code         => 3 character ISO 4217 compliant currency code (optional),
	);


If you are issuing a refund or credit memo for part of the order (for the full order
you may want to void the order using the C<cancel_tax()> method), you may need to specify
the date the tax was originally calculated, and you need to specify the amounts as
negative values.

	my $tax_results = $avalara_gateway->get_tax(
		document_type         => 'ReturnInvoice',
		document_code         => $original_order_number (optional), or a unique identifier
		document_date         => $date (optional), default is current date
		tax_override          => {
			reason            => 'Return',
			tax_override_type => 'TaxDate',
			tax_date          => 'YYYY-MM-DD', # Original date of the order.
		},
		# Just the lines being refunded.
		cart_lines            => [
			{
				sku      => $sku_identifier,
				quantity => $number_of_units_to_refund,
				amount   => $amount_to_refund,  # Negative value.
			},
		],
		discount              => $amount_to_decrease_refund (optional),  # Negative value.
		commit                => 1|0, # Default 0, whether this is a 'final' query.
		# Include other fields as needed.
	);

See below for the definitions of address and cart_line fields. The field origin_address
may be specified here if it changes between transactions, or in new if it's largely static.

detail level is one of 'Tax', 'Summary', 'Document', 'Line', or 'Diagnostic'.
See the Avalara documentation for the distinctions.

document_type is one of 'SalesOrder', 'SalesInvoice', 'PurchaseOrder', 'PurchaseInvoice',
'ReturnOrder', and 'ReturnInvoice'.

document_code is optional, but highly recommended. If you do not include this,
Avalara will generate a new internal unique id for each request, and it does not
associate the commits to any queries you made along the way.

If cache_timespan is set and you passed a memcached object into new(), it will attempt
to cache the result based on the unique key passed in.

Returns a perl hashref based on the Avalara return.
See the Avalara documentation for the full description of the output, but the highlights are:

	{
		ResultCode     => 'Success',
		TaxAddresses   => [ array of address information ],
		TaxDate        => Date,
		TaxLines       =>
		{
			LineNumber => # The value of the line number
			{
				Discount      => Discount,
				LineNo        => Line Number passed in,
				Rate          => Tax rate used,
				Tax           => Line item tax
				Taxability    => "true" or "false",
				Taxable       => Amount taxable,
				TaxCalculated => Line item tax
				TaxCode       => Tax Code used in the calculation
				Tax Details   => Details about state, county, city components of the tax
				
			},
			...
		},
		Timestamp      => Timestamp,
		TotalAmount    => Total amount before tax
		TotalDiscount  => Total Discount
		TotalExemption => Total amount exempt
		TotalTax       => Tax for the whole order
		TotalTaxable   => Amount that's taxable
	}
=cut

sub get_tax
{
	my ( $self, %args ) = @_;
	
	my $unique_key = delete $args{'unique_key'};
	my $cache_timespan = delete $args{'cache_timespan'};
	
	# Perl output, aka a hash ref, as opposed to JSON.
	my $tax_perl_output = undef;
	
	if ( defined( $cache_timespan ) )
	{
		# Cache event.
		$tax_perl_output = $self->get_cache(
			key         => $unique_key,
		);
	}
	
	if ( !defined $tax_perl_output )
	{
		# It wasn't in the cache or we aren't using cache, go get it.
		try
		{
			my $request_json = $self->_generate_request_json( %args );
			my $result_json = $self->_make_request_json( $request_json );
			$tax_perl_output = $self->_parse_response_json( $result_json );
		}
		catch
		{
			carp( "Failed to fetch Avalara tax information: ", $_ );
			return;
		};
		
		if ( defined( $cache_timespan ) )
		{
			# Set it in the cache.
			$self->set_cache(
				key         => $unique_key,
				value       => $tax_perl_output,
				expire_time => $cache_timespan,
			);
		}
	}
	return $tax_perl_output;
}


=head2 cancel_tax()

Makes a JSON request using the 'cancel_tax' method, parses the response, and returns a perl hash.

	my $tax_results = $avalara_gateway->cancel_tax(
		document_type => $document_type, default 'SalesOrder'
		doc_code      => $doc_code,
		cancel_code   => $cancel_code, default 'DocVoided',
		doc_id        => $doc_id,
	);

Either doc_id (which is Avalara's transaction ID returned from get_tax() )
or the combination of document_type, doc_coe, and doc_id are required.

Returns a perl hashref based on the Avalara return.
See the Avalara documentation for the full description of the output, but the highlights are:

	'CancelTaxResult' =>
	{
		ResultCode    => 'Success',
		DocID         => SomeDocID,
		TransactionID => Avalara's ID,
	}

=cut

sub cancel_tax
{
	my ( $self, %args ) = @_;
	
	my $document_type = delete $args{'document_type'} // 'SalesOrder';
	my $doc_code = delete $args{'doc_code'};
	my $cancel_code = delete $args{'cancel_code'} // 'DocVoided';
	my $doc_id = delete $args{'doc_id'};
	
	# We need either doc_id or doc_code and document_type and cancel_code.
	# But there are defaults on document_type and cancel type, so really
	# we just need doc_id or doc_code.
	if ( !defined $doc_id && !defined $doc_code )
	{
		carp( "Either a doc_id, or the combination of doc_code, cancel_code, and document_type is required." );
		return undef;
	}

	my %request;
	if ( defined $doc_id )
	{
		$request{'doc_id'} = $doc_id;
	}
	else
	{
		$request{'document_type'} = $document_type;
		$request{'doc_code'} = $doc_code;
		$request{'cancel_code'} = $cancel_code;
	}
	
	my $cancel_output = try
	{
		my $request_json = $self->_generate_cancel_request_json( %request );
		my $result_json = $self->_make_request_json( $request_json, 'cancel' );
		return $self->_parse_response_json( $result_json );
	}
	catch
	{
		carp( "Failed to cancel Avalara tax record: ", $_ );
		return undef;
	};

	return $cancel_output;
}


=head1 INTERNAL FUNCTIONS

=head2 _generate_request_json()

Generates the json to send to Avalara's web service.

Returns a JSON object.

=cut

sub _generate_request_json
{
	my ( $self, %args ) = @_;
	
	# Add in all the required elements.
	my @now = localtime();
	my $doc_date = defined $args{'doc_date'}
		? $args{'doc_date'}
		: sprintf( "%4d-%02d-%02d", $now[5] + 1900, $now[4] + 1, $now[3] );

	my $request =
	{
		DocDate      => $doc_date,
		CustomerCode => $self->{'customer_code'},
		CompanyCode  => $self->{'company_code'},
		Commit       => ( $args{'commit'} // 0 ) ? 'true' : 'false',
	};
	
	$request->{'Addresses'} = [ $self->_generate_address_json( $args{'destination_address'}, 1 ) ];
	push @{ $request->{'Addresses'} },
		$self->_generate_address_json( $self->{'origin_address'} // $args{'origin_address'}, 2 );
	
	$request->{'Lines'} = [];
	
	my $counter = 1;
	foreach my $cart_line ( @{ $args{'cart_lines'} } )
	{
		push @{ $request->{'Lines'} }, $self->_generate_cart_line_json( $cart_line, $counter );
		$counter++;
	}
	
	my %optional_nodes =
	(
		customer_usage_type   => 'CustomerUsageType',
		discount              => 'Discount',
		purchase_order_number => 'PurchaseOrderNo',
		exemption_number      => 'ExemptionNo',
		detail_level          => 'DetailLevel',
		document_type         => 'DocType',
		payment_date          => 'PaymentDate',
		reference_code        => 'ReferenceCode',
		document_code         => 'DocCode',
		currency_code         => 'CurrencyCode',
	);
	
	foreach my $node_name ( keys %optional_nodes )
	{
		next if ( !defined $args{ $node_name } );
		$request->{ $optional_nodes{ $node_name } } = $args{ $node_name };
	}
	
	my %tax_override_nodes =
	(
		'reason'              => 'Reason', # Typical reasons include: 'Return', 'Layaway', 'Imported'.
		'tax_override_type'   => 'TaxOverrideType', # None, TaxAmount, Exemption, or TaxDate.
		'tax_date'            => 'TaxDate', # Date the tax was calculated (if type is TaxDate).
		'tax_amount'          => 'TaxAmount', # The amount of tax to apply (if type is TaxAmount).
	);

	# Fill in the TaxOverride values.
	if ( defined $args{'tax_override'} )
	{
		foreach my $node ( keys %tax_override_nodes )
		{
			if ( defined $args{'tax_override'}{ $node } )
			{
				$request->{'TaxOverride'}{ $tax_override_nodes{ $node } } = $args{'tax_override'}{ $node };
			}
		}
	}

	my $json = JSON::PP->new()->ascii()->pretty()->allow_nonref();
	return $json->encode( $request );
}


=head2 _generate_cancel_request_json()

Generates the json to cancel a tax request to Avalara's web service.

Returns a JSON object.

=cut

sub _generate_cancel_request_json
{
	my ( $self, %args ) = @_;
	
	my $request =
	{
		CompanyCode => $self->{'company_code'},
	};
	
	my %optional_nodes =
	(
		document_type => 'DocType',
		doc_code      => 'DocCode',
		cancel_code   => 'CancelCode',
		doc_id        => 'DocId',
	);
	
	foreach my $node_name ( keys %optional_nodes )
	{
		next if ( !defined $args{ $node_name } );
		$request->{ $optional_nodes{ $node_name } } = $args{ $node_name };
	}

	my $json = JSON::PP->new()->ascii()->pretty()->allow_nonref();
	return $json->encode( $request );
}


=head2 _generate_address_json()

Given an address hashref, generates and returns a data structure to be converted to JSON.

An address hashref is defined as:

	my $address = {
		line_1        => $first_line_of_address,
		line_2        => $second_line_of_address,
		line_3        => $third_line_of_address,
		city          => $city,
		region        => $state_or_province,
		country       => $iso_2_code,
		postal_code   => $postal_or_ZIP_code,
		latitude      => $latitude,
		longitude     => $longitude,
		tax_region_id => $tax_region_id,
	};
	
All fields are optional, though without enough to identify an address, your results will
be less than satisfying.

Country coes are ISO 3166-1 (alpha 2) format, such as 'US'.

=cut

sub _generate_address_json
{
	my ( $self, $address, $address_code ) = @_;
	
	my $address_request = {};
	
	# Address code is just an internal identifier. In this module, 1 is destination, 2 is origin.
	$address_request->{'AddressCode'} = $address_code;
	
	my %nodes =
	(
		'line_1'        => 'Line1',
		'line_2'        => 'Line2',
		'line_3'        => 'Line3',
		'city'          => 'City',
		'region'        => 'Region',
		'country'       => 'Country',
		'postal_code'   => 'PostalCode',
		'latitude'      => 'Latitude',
		'longitude'     => 'Longitude',
		'tax_region_id' => 'TaxRegionId',
	);
	
	foreach my $node ( keys %nodes )
	{
		if ( defined $address->{ $node } )
		{
			$address_request->{ $nodes{ $node } } = $address->{ $node };
		}
	}
	
	return $address_request;
}


=head2 _generate_cart_line_json()

Generates a data structure from a cart_line hashref. Cart lines are:

	my $cart_line = {
		'line_number'         => $number (optional, will be generated if omitted.),
		'item_code'           => $item_code
		'sku'                 => $sku, # Use sku OR item_code
		'tax_code'            => $tax_code,
		'customer_usage_type' => $customer_usage_code
		'description'         => $description,
		'quantity'            => $quantity,
		'amount'              => $amount, # Extended price, ie, price * quantity
		'discounted'          => $is_included_in_discount, # Boolean (True or False)
		'tax_included'        => $is_tax_included, # Boolean (True or False)
		'ref_1'               => $reference_1,
		'ref_2'               => $reference_2,
	}
	
One of item_code or sku, quantity, and amount are required fields.

Customer usage type determines the type of item (sometimes called entity or use code). In some
states, different types of items have different tax rates.

=cut

sub _generate_cart_line_json
{
	my ( $self, $cart_line, $counter ) = @_;
	
	my $cart_line_request = {};

	$cart_line_request->{'LineNo'} = $cart_line->{'line_number'} // $counter;	
	
	# By convention, destionation is address 1, origin is address 2, in this module.
	# It doesn't matter in the slightest, the labels just have to match.
	$cart_line_request->{'DestinationCode'} = 1;
	$cart_line_request->{'OriginCode'} = 2;
	
	my %nodes =
	(
		'item_code'           => 'ItemCode',
		'sku'                 => 'ItemCode', # Use sku OR item_code
		'tax_code'            => 'TaxCode',
		'customer_usage_type' => 'CustomerUsageType',
		'description'         => 'Description',
		'quantity'            => 'Qty',
		'amount'              => 'Amount', # Extended price, ie, price * quantity
		'discounted'          => 'Discounted', # Boolean
		'tax_included'        => 'TaxIncluded', # Boolean
		'ref_1'               => 'Ref1',
		'ref_2'               => 'Ref2',
	);

	foreach my $node ( keys %nodes )
	{
		if ( defined $cart_line->{ $node } )
		{
			$cart_line_request->{ $nodes{ $node } } = $cart_line->{ $node };
		}
	}

	my %tax_override_nodes =
	(
		'reason'              => 'Reason', # Typical reasons include: 'Return', 'Layaway', 'Imported'.
		'tax_override_type'   => 'TaxOverrideType', # None, TaxAmount, Exemption, or TaxDate.
		'tax_date'            => 'TaxDate', # Date the tax was calculated (if type is TaxDate).
		'tax_amount'          => 'TaxAmount', # The amount of tax to apply (if type is TaxAmount).
	);

	# Fill in the TaxOverride values.
	if ( defined $cart_line->{'tax_override'} )
	{
		foreach my $node ( keys %tax_override_nodes )
		{
			if ( defined $cart_line->{'tax_override'}{ $node } )
			{
				$cart_line_request->{'TaxOverride'}{ $tax_override_nodes{ $node } } = $cart_line->{'tax_override'}{ $node };
			}
		}
	}
	
	return $cart_line_request;
}


=head2 _make_request_json()

Makes the https request to Avalara, and returns the response json.

=cut

sub _make_request_json
{
	my ( $self, $request_json, $resource ) = @_;
		
	$resource //= 'get';
	
	my $request_server = $self->{'is_development'}
		? $AVALARA_DEVELOPMENT_REQUEST_SERVER
		: $AVALARA_REQUEST_SERVER;
	my $request_url = 'https://' . $request_server . '/1.0/tax/' . $resource;
	
	# Create a user agent object
	my $user_agent = LWP::UserAgent->new();
	$user_agent->agent( "perl/Business-Tax-Avalara/$VERSION" );
	$user_agent->timeout( $self->{'request_timeout'} );
	
	# Create a request
	my $request = HTTP::Request::Common::POST(
		$request_url,
	);
	
	$request->authorization_basic(
		$self->{'user_name'},
		$self->{'password'},
	);
	
	$request->header( content_type => 'text/json' );
	$request->content( $request_json );
	$request->header( content_length => length( $request_json ) );
	
	if ( $self->{'debug'} )
	{
		carp( 'Request to Avalara: ', Data::Dump::dump( $request->content() ) );
	}
	
	# Pass request to the user agent and get a response back
	my $response = $user_agent->request( $request );
	
	if ( $self->{'debug'} )
	{
		carp( 'Response from Avalara: ', Data::Dump::dump( $response->content() ) );
	}

	# Check the outcome of the response
	if ( $response->is_success() )
	{
		return $response->content();
	}
	else
	{
		carp $response->status_line();
		carp $request->as_string();
		carp $response->as_string();
		carp "Failed to fetch JSON response: " . $response->status_line() . "\n";
		return $response->content();
	}
	
	return;
}


=head2 _parse_response_json()

Converts the returned JSON into a perl hash.

=cut

sub _parse_response_json
{
	my ( $self, $response_json ) = @_;
	
	my $json = JSON::PP->new()->ascii()->pretty()->allow_nonref();
	my $perl = $json->decode( $response_json );
	
	my $lines = delete $perl->{'TaxLines'};
	foreach my $line ( @$lines )
	{
		$perl->{'TaxLines'}->{ $line->{'LineNo'} } = $line;
	}
	
	return $perl;
}



=head2 get_memcache()

Return the database handle tied to the audit object.

	my $memcache = $avalara_gateway->get_memcache();

=cut

sub get_memcache
{
	my ( $self ) = @_;

	return $self->{'memcache'};
}


=head2 get_cache()

Get a value from the cache.

	my $value = $avalara_gateway->get_cache( key => $key );

=cut

sub get_cache
{
	my ( $self, %args ) = @_;
	my $key = delete( $args{'key'} );
	croak 'Invalid argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;
	
	# Check parameters.
	croak 'The parameter "key" is mandatory'
		if !defined( $key ) || $key !~ /\w/;
	
	my $memcache = $self->get_memcache();
	return
		if !defined( $memcache );
	
	return $memcache->get( $key );
}


=head2 set_cache()

Set a value into the cache.

	$avalara_gateway->set_cache(
		key         => $key,
		value       => $value,
		expire_time => $expire_time,
	);

=cut

sub set_cache
{
	my ( $self, %args ) = @_;
	my $key = delete( $args{'key'} );
	my $value = delete( $args{'value'} );
	my $expire_time = delete( $args{'expire_time'} );
	croak 'Invalid argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;
	
	# Check parameters.
	croak 'The parameter "key" is mandatory'
		if !defined( $key ) || $key !~ /\w/;
	
	my $memcache = $self->get_memcache();
	return
		if !defined( $memcache );
	
	$memcache->set( $key, $value, $expire_time )
		|| carp 'Failed to set cache with key >' . $key . '<';
	
	return;
}


=head1 AUTHOR

Kate Kirby, C<< <kate at cpan.org> >>.


=head1 MAINTAINER

Nathan Gray E<lt>kolibrie@cpan.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-tax-avalara at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-Tax-Avalara>. 
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Business::Tax::Avalara


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-Tax-Avalara>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-Tax-Avalara>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-Tax-Avalara>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-Tax-Avalara/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to ThinkGeek (L<http://www.thinkgeek.com/>) and its corporate overlords
at Geeknet (L<http://www.geek.net/>), for footing the bill while we eat pizza
and write code for them!


=head1 COPYRIGHT & LICENSE

Copyright 2012 Kate Kirby.

Copyright (C) 2017 Nathan Gray

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/

=cut

1;
