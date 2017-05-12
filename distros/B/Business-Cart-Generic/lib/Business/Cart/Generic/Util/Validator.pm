package Business::Cart::Generic::Util::Validator;

use strict;
use warnings;

use Brannigan;

use CGI::Untaint;

use Moose;

extends 'Business::Cart::Generic::Database::Base';

has query =>
(
 is  => 'ro',
 isa => 'CGI',
 required => 1,
);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub clean_user_data
{
	my($self, $data, $max_length, $integer) = @_;
	$max_length  ||= 255;
	$data = '' if (! defined($data) || (length($data) == 0) || (length($data) > $max_length) );
	#$data = '' if ($data =~ /<script\s*>.+<\s*\/?\s*script\s*>/i);	# http://www.perl.com/pub/a/2002/02/20/css.html.
	$data = '' if ($data =~ /<(.+)\s*>.*<\s*\/?\s*\1\s*>/i);		# Ditto, but much more strict.
	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	$data = 0 if ($integer && (! $data || ($data !~ /^[0-9]+$/) ) );

	return $data;

}	# End of clean_user_data.

# --------------------------------------------------

sub validate_order
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'validate_order()');

 	my($handler) = CGI::Untaint -> new(map{$_ => $self -> query -> param($_)} $self -> query -> param);
	my($data)    = {};

	my($key);

	for $key (qw/sid/)
	{
		$$data{$key} = $handler -> extract(-as_hex => $key);
	}

	for $key (qw/
billing_address_id
country_id
customer_address_id
customer_id
delivery_address_id
payment_method_id
product_id
quantity
tax_class_id
zone_id
/)
	{
		$$data{$key} = $handler -> extract(-as_integer => $key);
	}

	# We use the key product to validate both product_id and quantity.

	$$data{product} = 1;
	my($validator)  = Brannigan -> new
	({
		ignore_missing => 0,
		name   => 'validate_order',
		params =>
		{
			billing_address_id =>
			{
				required => 1,
				validate => sub{return $self -> db -> validate_street_address_id(shift)},
			},
			country_id =>
			{
				required => 1,
				validate => sub{return $self -> db -> validate_country_id(shift)},
			},
			customer_address_id =>
			{
				required => 1,
				validate => sub{return $self -> db -> validate_street_address_id(shift)},
			},
			customer_id =>
			{
				required => 1,
				validate => sub{return $self -> db -> validate_customer_id(shift)},
			},
			delivery_address_id =>
			{
				required => 1,
				validate => sub{return $self -> db -> validate_street_address_id(shift)},
			},
			payment_method_id =>
			{
				required => 1,
				validate => sub{return $self -> db -> validate_payment_method_id(shift)},
			},
			product =>
			{
				required => 1, # The 2 (digits) is because we arbitrarily restrict quantity to the range 1 .. 2 dozen.
				validate => sub{return $self -> db -> validate_product(shift, $self -> clean_user_data($$data{quantity}, 2, 1))},
			},
			tax_class_id =>
			{
				required => 1,
				validate => sub{return $self -> db -> validate_tax_class_id(shift)},
			},
			zone_id =>
			{
				required => 1,
				validate => sub{return $self -> db -> validate_zone_id(shift)},
			},
			sid =>
			{
				exact_length => 32,
				required     => 1,
			},
		},
	 });

	return $validator -> process('validate_order', $data);

} # End of validate_order.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Util::Validator> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class extends L<Business::Cart::Generic::Database::Base>.

=head2 Using new()

C<new()> is called as C<< my($obj) = Business::Cart::Generic::Util::Validator -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::Util::Validator>.

Key-value pairs accepted in the parameter list:

=over 4

=item o query => $query

Takes an object of type L<CGI> or similar.

This key => value pair is mandatory.

=back

=head1 Methods

=head2 clean_user_data($data, $max_length, $integer)

Used internally.

=head2 validate_order()

Validates the form parameters retrieved from the query object.

Returns the hashref returned from the process() method of the L<Brannigan> class.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who chose to make osCommerce and PrestaShop, Zen Cart, etc, Open Source.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business::Cart::Generic>.

=head1 Author

L<Business::Cart::Generic> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
