package Business::OnlinePayment::InternetSecure;

use 5.008;
use strict;
use warnings;

use Carp;
use Encode;
use Net::SSLeay qw(make_form post_https);
use XML::Simple qw(xml_in xml_out);

use base qw(Business::OnlinePayment Exporter);


our $VERSION = '0.10';


use constant SUCCESS_CODES => qw(2000 90000 900P1);

use constant CARD_TYPES => {
				AM => 'American Express',
				JB => 'JCB',
				MC => 'MasterCard',
				NN => 'Discover',
				VI => 'Visa',
			};


# Convenience functions to avoid undefs and escape products strings
sub _def($) { defined $_[0] ? $_[0] : '' }
sub _esc($) { local $_ = shift; tr/|:/ /s; tr/"`/'/s; return $_ }


sub set_defaults {
	my ($self) = @_;

	$self->server('secure.internetsecure.com');
	$self->port(443);
	$self->path('/process.cgi');

	$self->build_subs(qw(
				receipt_number	order_number	uuid	guid
				date
				card_type	cardholder
				total_amount	tax_amounts
				avs_code	cvv2_response
			));

	# Just in case someone tries to call tax_amounts() *before* submit()
	$self->tax_amounts( {} );
}

# Backwards-compatible support for renamed fields
sub avs_response { shift()->avs_code(@_) }
sub sales_number { shift()->order_number(@_) }


# Combine get_fields and remap_fields for convenience.  Unlike OnlinePayment's
# remap_fields, this doesn't modify content(), and can therefore be called
# more than once.  Also, unlike OnlinePayment's get_fields in 3.x, this doesn't
# exclude undefs.
#
sub get_remap_fields {
	my ($self, %map) = @_;

	my %content = $self->content();
	my %data;

	while (my ($to, $from) = each %map) {
		$data{$to} = $content{$from};
	}

	return %data;
}

# Since there's no standard format for expiration dates, we try to do our best
#
sub parse_expdate {
	my ($self, $str) = @_;

	local $_ = $str;

	my ($y, $m);

	if (/^(\d{4})\W(\d{1,2})$/ ||		# YYYY.MM  or  YYYY-M
			/^(\d\d)\W(\d)$/ ||	# YY/M  or  YY-M
			/^(\d\d)[.-](\d\d)$/) {	# YY-MM
		($y, $m) = ($1, $2);
	} elsif (/^(\d{1,2})\W(\d{4})$/ ||	# MM-YYYY  or  M/YYYY
			/^(\d)\W(\d\d)$/ ||	# M/YY  or  M-YY
			/^(\d\d)\/?(\d\d)$/) {	# MM/YY  or  MMYY
		($y, $m) = ($2, $1);
	} else {
		croak "Unable to parse expiration date: $str";
	}

	$y += 2000 if $y < 2000;  # Aren't we glad Y2K is behind us?

	return ($y, $m);
}

# Convert a single product into a product string
#
sub prod_string {
	my ($self, $currency, %data) = @_;

	croak "Missing amount in product" unless defined $data{amount};

	my @flags = ($currency);

	my @taxes;
	if (ref $data{taxes}) {
		@taxes = @{ $data{taxes} };
	} elsif ($data{taxes}) {
		@taxes = split ' ' => $data{taxes};
	}

	foreach (@taxes) {
		croak "Unknown tax code $_" unless /^(GST|PST|HST)$/i;
		push @flags, uc $_;
	}

	if ($self->test_transaction) {
		push @flags, $self->test_transaction < 0 ? 'TESTD' : 'TEST';
	}

	# recurring can come as string or hashref
	if ($data{recurring}) {
		if (ref $data{recurring}) {
			my @options;
			push @options, 'RB';
			foreach my $key ( sort keys %{ $data{recurring} } ) {
				push @options, $key . '=' . $data{recurring}{$key};
			}
			push @flags, join ' ', @options;
		} else {
			push @flags, "RB $data{recurring}";
		}
	}

	return join '::' =>
				sprintf('%.2f' => $data{amount}),
				$data{quantity} || 1,
				_esc _def $data{sku},
				_esc _def $data{description},
				join('' => map "{$_}" => @flags),
				;
}

# Generate the XML document for this transaction
#
sub to_xml {
	my ($self) = @_;

	my %content = $self->content;

	# Backwards-compatible support for exp_date
	if (exists $content{exp_date} && ! exists $content{expiration}) {
		$content{expiration} = delete $content{exp_date};
		$self->content(%content);
	}

	$self->required_fields(qw(action card_number expiration));

	croak "Unsupported card type: $content{type}"
		if $content{type} &&
			! grep lc($content{type}) eq lc($_),
				values %{+CARD_TYPES}, 'CC';

	croak 'Unsupported action'
		unless $content{action} =~ /^(Normal|Card) Authori[zs]ation$/i;

	$content{currency} = uc($content{currency} || 'CAD');
	croak "Unknown currency code ", $content{currency}
		unless $content{currency} =~ /^(CAD|USD)$/;

	my %data = $self->get_remap_fields(qw(
			xxxCard_Number		card_number

			xxxName			name
			xxxCompany		company
			xxxAddress		address
			xxxCity			city
			xxxProvince		state
			xxxPostal		zip
			xxxCountry		country
			xxxPhone		phone
			xxxEmail		email

			xxxShippingName		ship_name
			xxxShippingCompany	ship_company
			xxxShippingAddress	ship_address
			xxxShippingCity		ship_city
			xxxShippingProvince	ship_state
			xxxShippingPostal	ship_zip
			xxxShippingCountry	ship_country
			xxxShippingPhone	ship_phone
			xxxShippingEmail	ship_email

			xxxCustomerDB		cimb_store
		));

	$data{MerchantNumber} = $self->merchant_id;

	$data{xxxCard_Number} =~ tr/- //d;
	$data{xxxCard_Number} =~ s/^[^3-6]/4/ if $self->test_transaction;

	my ($y, $m) = $self->parse_expdate($content{expiration});
	$data{xxxCCYear} = sprintf '%.4u' => $y;
	$data{xxxCCMonth} = sprintf '%.2u' => $m;

	delete $data{xxxCustomerDB} unless $data{xxxCustomerDB};

	# Recurring
	if (defined $content{recurring} && $content{recurring} ne '') {
		$data{xxxCardInput} = 8;
	}

	if (defined $content{cvv2} && $content{cvv2} ne '') {
		$data{CVV2} = $content{cvv2};
		$data{CVV2Indicator} = 1;
	} else {
		$data{CVV2} = '';
		$data{CVV2Indicator} = 0;
	}

	if ($content{action} =~ /^Card Authori[zs]ation$/i) {
		$data{xxxTransType} = 22;

		$data{Products} = $self->prod_string(
					$content{currency},
					taxes       => 0,
					amount      => 0.0,
					description => 'CardAuth and Store',
				);
	} else {

		if (ref $content{description}) {
			$data{Products} = join '|' => map $self->prod_string(
							$content{currency},
							taxes => $content{taxes},
							%$_),
						@{ $content{description} };
		} else {
			$self->required_fields(qw(amount));
			$data{Products} = $self->prod_string(
						$content{currency},
						taxes       => $content{taxes},
						amount      => $content{amount},
						description => $content{description},
						recurring   => $content{recurring},
					);
		}

	}

	# The encode() makes sure to a) strip off non-Latin-1 characters, and
	# b) turn off the utf8 flag, which confuses XML::Simple
	encode('ISO-8859-1', xml_out(\%data,
		NoAttr		=> 1,
		RootName	=> 'TranxRequest',
		SuppressEmpty	=> undef,
		XMLDecl		=> '<?xml version="1.0" encoding="iso-8859-1" standalone="yes"?>',
	));
}

# Map the various fields from the response, and put their values into our
# object for retrieval.
#
sub infuse {
	my ($self, $data, %map) = @_;

	while (my ($k, $v) = each %map) {
		no strict 'refs';
		$self->$k($data->{$v});
	}
}

sub extract_tax_amounts {
	my ($self, $response) = @_;

	my %tax_amounts;

	my $products = $response->{Products};
	return unless $products;

	foreach my $node (@$products) {
		my $flags = $node->{flags};
		if ($flags &&
			grep($_ eq '{TAX}', @$flags) &&
			grep($_ eq '{CALCULATED}', @$flags))
		{
			$tax_amounts{ $node->{code} } = $node->{subtotal};
		}
	}

	return %tax_amounts;
}

# Parse the server's response and set various fields
#
sub parse_response {
	my ($self, $response) = @_;

	$self->server_response($response);

	local $/ = "\n";  # Make sure to avoid bug #17687

	$response = xml_in($response,
 			ForceArray => [qw(product flag)],
 			GroupTags => { qw(Products product flags flag) },
 			KeyAttr => [],
 			SuppressEmpty => undef,
		);

	$self->infuse($response,
			result_code	=> 'Page',
			error_message	=> 'Verbiage',
			authorization	=> 'ApprovalCode',
			avs_code	=> 'AVSResponseCode',
			cvv2_response	=> 'CVV2ResponseCode',

			receipt_number	=> 'ReceiptNumber',
			order_number	=> 'SalesOrderNumber',
			uuid		=> 'GUID',
			guid		=> 'GUID',

			date		=> 'Date',
			cardholder	=> 'xxxName',
			card_type	=> 'CardType',
			total_amount	=> 'TotalAmount',
			);

	$self->is_success(scalar grep $self->result_code eq $_, SUCCESS_CODES);

	# Completely undocumented field that sometimes override <Verbiage>
	$self->error_message($response->{Error}) if $response->{Error};

	# Delete error_message if transaction was successful
	$self->error_message(undef) if $self->is_success;

	$self->card_type(CARD_TYPES->{$self->card_type});

	$self->tax_amounts( { $self->extract_tax_amounts($response) } );

	return $self;
}

sub submit {
	my ($self) = @_;

	croak "Missing required argument 'merchant_id'"
		unless defined $self->{merchant_id};

	my ($page, $response, %headers) =
		post_https(
				$self->server,
				$self->port,
				$self->path,
				undef,
				make_form(
					xxxRequestMode => 'X',
					xxxRequestData => $self->to_xml,
				)
			);

	croak 'Error connecting to server' unless $page;
	croak 'Server responded, but not in XML' unless $page =~ /^<\?xml/;

	# The response is marked UTF-8, but it's really Latin-1.  Sigh.
	$page =~ s/^(<\?xml.*?) encoding="utf-8"/$1 encoding="iso-8859-1"/si;

	$self->parse_response($page);
}


1;

__END__
=encoding utf-8

=head1 NAME

Business::OnlinePayment::InternetSecure - InternetSecure backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $txn = new Business::OnlinePayment 'InternetSecure',
  					merchant_id => '0000';

  $txn->content(
	action		=> 'Normal Authorization', # or 'Card Authentication'

  	type		=> 'Visa',			# Optional
	card_number	=> '4111 1111 1111 1111',
	expiration	=> '2004-07',
	cvv2		=> '000',			# Optional

	name		=> "Fr\x{e9}d\x{e9}ric Bri\x{e8}re",
	company		=> '',
	address		=> '123 Street',
	city		=> 'Metropolis',
	state		=> 'ZZ',
	zip		=> 'A1A 1A1',
	country		=> 'CA',
	phone		=> '(555) 555-1212',
	email		=> 'fbriere@fbriere.net',

	amount		=> 49.95,
	currency	=> 'CAD',
	taxes		=> 'GST PST',
	description	=> 'Test transaction',

	recurring       => 'amount=9.95 startmonth=+1 frequency=monthly duration=3 email=2',

	cimb_store      => 1, # Tokenization Support

	test_transaction => 1, # or -1 to dest declined
	);

  $txn->submit;

  if ($txn->is_success) {
  	print "Card processed successfully: " . $txn->authorization . "\n";
  } else {
  	print "Card was rejected: " . $txn->error_message . "\n";
  }

=head1 DESCRIPTION

C<Business::OnlinePayment::InternetSecure> is an implementation of
C<Business::OnlinePayment> that allows for processing online credit card
payments through InternetSecure.

See L<Business::OnlinePayment> for more information about the generic
Business::OnlinePayment interface.

=head1 CREATOR

Object creation is done via C<Business::OnlinePayment>; see its manpage for
details.  The B<merchant_id> processor option is required, and corresponds
to the merchant ID assigned to you by InternetSecure.

=head1 METHODS

=head2 Transaction setup and transmission

=over 4

=item content( CONTENT )

Sets up the data prior to a transaction.  CONTENT is an associative array
(hash), containing some of the following fields:

=over 4

=item action (required)

What to do with the transaction. C<Normal Authorization> and C<Card Authorization> are supported
at the moment.

=item type

Card type, being one of the following:

=over 4

=item - Visa

=item - MasterCard

=item - American Express

=item - Discover

=item - JCB

=item - CC

=back

(This is actually ignored for the moment, and can be left blank or undefined.)

=item card_number (required)

Credit card number.  Spaces and dashes are automatically removed.

=item expiration (required)

Credit card expiration date.  Since C<Business::OnlinePayment> does not specify
any syntax, this module is rather lax regarding what it will accept.  The
recommended syntax is C<YYYY-MM>, but forms such as C<MM/YYYY> or C<MMYY> are
allowed as well.

=item cvv2

Three- or four-digit verification code printed on the card.  This can be left
blank or undefined, in which case no check will be performed.  Whether or not a
transaction will be declined in case of a mismatch depends on the merchant
account configuration.

This number may be called Card Verification Value (CVV2), Card Validation
Code (CVC2) or Card Identification number (CID), depending on the card issuer.

=item description

A short description of the transaction.  See L<"Products list syntax"> for
an alternate syntax that allows a list of products to be specified.

=item amount (usually required)

Total amount to be billed, excluding taxes if they are to be added separately
by InternetSecure.

This field is required if B<description> is a string, but should be left
undefined if B<description> contains a list of products instead, as outlined
in L<"Products list syntax">.

=item currency

Currency of all amounts for this order.  This can currently be either
C<CAD> (default) or C<USD>.

=item taxes

Taxes to be added automatically to B<amount> by InternetSecure.  Available
taxes are C<GST>, C<PST> and C<HST>.

This argument can either be a single string of taxes concatenated with spaces
(such as C<GST PST>), or a reference to an array of taxes (such as C<[ "GST",
"PST" ]>).

=item name / company / address / city / state / zip / country / phone / email

Customer information.  B<country> should be a two-letter code taken from ISO
3166-1.

=back

=item submit()

Submit the transaction to InternetSecure.

=back

=head2 Post-submission methods

=over 4

=item is_success()

Returns true if the transaction was submitted successfully.

=item result_code()

Response code returned by InternetSecure.

=item error_message()

Error message if the transaction was unsuccessful; C<undef> otherwise.  (You
should not rely on this to test whether a transaction was successful; use
B<is_success>() instead.)

=item receipt_number()

Receipt number (a string, actually) of this transaction, unique to all
InternetSecure transactions.

=item order_number()

Sales order number of this transaction.  This is a number, unique to each
merchant, which is incremented by 1 each time.

=item uuid()

Universally Unique Identifier associated to this transaction.  This is a
128-bit value returned as a 36-character string such as
C<f81d4fae-7dec-11d0-a765-00a0c91e6bf6>.  See RFC 4122 for more details on
UUIDs.

B<guid>() is provided as an alias to this method.

=item authorization()

Authorization code for this transaction.

=item avs_code() / cvv2_response()

Results of the AVS and CVV2 checks.  See the InternetSecure documentation for
the list of possible values.

=item date()

Date and time of the transaction.  Format is C<YYYY/MM/DD hh:mm:ss>.

=item total_amount()

Total amount billed for this order, including taxes.

=item tax_amounts()

Returns a I<reference> to a hash that maps taxes, which were listed under the
B<taxes> argument to B<submit>(), to the amount that was calculated by
InternetSecure.

=item cardholder()

Cardholder's name.  This is currently a mere copy of the B<name> field passed
to B<submit>().

=item card_type()

Type of the credit card used for the submitted order, being one of the
following:

=over 4

=item - Visa

=item - MasterCard

=item - American Express

=item - Discover

=item - JCB

=back


=back


=head1 NOTES

=head2 Products list syntax

Optionally, the B<description> field of B<content>() can contain a reference
to an array of products, instead of a simple string.  Each element of this
array represents a different product, and must be a reference to a hash with
the following fields:

=over 4

=item amount (required)

Unit price of this product.

=item quantity

Ordered quantity of this product.

=item sku

Internal code for this product.

=item description

Description of this product

=item taxes

Taxes that should be automatically added to this product.  If specified, this
overrides the B<taxes> field passed to B<content>().

=back

When using a products list, the B<amount> field passed to B<content>() should
be left undefined.


=head2 Character encoding

When using non-ASCII characters, all data provided to B<contents>() should
have been decoded beforehand via the C<Encode> module, unless your data is in
ISO-8859-1 and you haven't meddled with the C<encoding> pragma.  (Please
don't.)

InternetSecure currently does not handle characters outside of ISO-8859-1, so
these will be replaced with C<?> before being transmitted.


=head1 EXPORT

None by default.


=head1 SEE ALSO

L<Business::OnlinePayment>

=head1 AUTHORS

Frédéric Brière, E<lt>fbriere@fbriere.netE<gt>

Slobodan Mišković, E<lt>slobodan.miskovic@taskforce-1.comE<gt>, http://www.taskforce-1.com/

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Frédéric Brière

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
