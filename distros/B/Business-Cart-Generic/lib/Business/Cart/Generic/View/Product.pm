package Business::Cart::Generic::View::Product;

use strict;
use warnings;

use JSON::XS;

use Moose;

use Text::Xslate 'mark_raw';

extends 'Business::Cart::Generic::View::Base';

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub format_products
{
	my($self, $product) = @_;

	$self -> db -> logger -> log(debug => "format_products(...)");

	my(@row);

	push @row,
	[
		{td => 'Name'},
		{td => 'Description'},
		{td => 'Price'},
		{td => 'Currency'},
	];

	for my $item (@$product)
	{
		push @row,
		[
		{td => $$item{name} },
		{td => $$item{description} },
		{td => $$item{price} },
		{td => $$item{currency} },
		];
	}

	push @row,
	[
		{td => 'Name'},
		{td => 'Description'},
		{td => 'Price'},
		{td => 'Currency'},
	];

	return \@row;

} # End of format_products.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::View::Product> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class extends L<Business::Cart::Generic::View::Base>.

=head2 Using new()

C<new()> is called as C<< my($obj) = Business::Cart::Generic::View::Product -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::View::Product>. See L<Business::Cart::Generic::View>.

Key-value pairs accepted in the parameter list:

=over 4

=item o config => $config

Takes an object of type L<Business::Cart::Generic::Util::Config>.

This key => value pair is mandatory.

=item o db => $db

Takes an object of type L<Business::Cart::Generic::Database>.

This key => value pair is mandatory.

=item o templater => $templater

Takes a L<Text::Xslate> object.

This key => value pair is mandatory.

=back

These keys are also getter-type methods. config() returns a hashref, and templater() returns an object.

=head1 Methods

=head2 config()

Returns a hashref.

=head2 db()

Returns an object of type L<Business::Cart::Generic::Database>.

=head2 format_products($product)

$product is an arrayref of hashref of inflated products as returned by L<Business::Cart::Generic::Database::Export/read_products_table()>.

Returns a set of HTML table rows. This data is used by L<Business::Cart::Generic::Database::Export/products_as_html()>.

=head2 templater()

Returns an object of type L<Text::Xslate>.

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
