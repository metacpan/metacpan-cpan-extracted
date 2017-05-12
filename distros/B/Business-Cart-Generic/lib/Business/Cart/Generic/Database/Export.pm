package Business::Cart::Generic::Database::Export;

use strict;
use warnings;

use CGI;

use Business::Cart::Generic::Database;
use Business::Cart::Generic::View;

use Moose;

use Path::Class; # For file().

use Text::CSV_XS;
use Text::Xslate 'mark_raw';

extends 'Business::Cart::Generic::Database::Base';

has db =>
(
 is       => 'rw',
 isa      => 'Business::Cart::Generic::Database',
 required => 0,
);

has view =>
(
 is       => 'rw',
 isa      => 'Business::Cart::Generic::View',
 required => 0,
);

has tx =>
(
 is       => 'rw',
 isa      => 'Text::Xslate',
 required => 0,
);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> db
		(
		 Business::Cart::Generic::Database -> new
		 (
		  query => CGI -> new,
		 )
		);

	$self -> tx
		(
		 Text::Xslate -> new
		 (
		  input_layer => '',
		  path        => ${$self -> config}{template_path},
		  )
		);

	$self -> view
		(
		 Business::Cart::Generic::View -> new
		 (
		  db        => $self -> db,
		  templater => $self -> tx,
		 )
		);

}	# End of BUILD.

# -----------------------------------------------

sub orders_as_html
{
	my($self)       = @_;
	my($config)     = $self -> config;
	my($order_path) = $$config{order_html_path};
	my($order_url)  = $$config{order_html_url};

	my($id);
	my(%page_name, $page_name);

	for my $order (@{$self -> read_orders_table})
	{
		$id             = $$order{id};
		$page_name{$id} = "order.$id.html";
		$page_name      = file($order_path, $page_name{$id});

		open(OUT, '>', $page_name) || die "Can't open($page_name): $!";
		print OUT $self -> tx -> render
			(
			 'export.order.page.tx',
			 {
				 border => 0,
				 id     => $id,
				 row    => $self -> view -> order -> format_search_order($order),
			 }
			);
		close OUT;

		print "Saved $page_name. \n";
	}

	$page_name{0} = file($order_path, "orders.html");

	open(OUT, '>', $page_name{0}) || die "Can't open($page_name{0}): $!";
	print OUT $self -> tx -> render
		(
		 'export.order.index.page.tx',
		 {
			 borders => 1,
			 css_url => $$config{css_url},
			 row     => [map{[{td => mark_raw(qq|<a href="$order_url/$page_name{$_}">Order # $_</a>|)}]} sort grep{! /^0$/} keys %page_name],
		 }
		);
	close OUT;

	print "Saved $page_name{0}. \n";

} # End of orders_as_html.

# -----------------------------------------------

sub products_as_html
{
	my($self)       = @_;
	my($config)     = $self -> config;
	my($order_path) = $$config{order_html_path};
	my($order_url)  = $$config{order_html_url};
	my($page_name)  = file($order_path, 'products.html');

	open(OUT, '>', $page_name) || die "Can't open($page_name): $!";
	print OUT $self -> tx -> render
		(
		 'basic.table.tx',
		 {
			 border => 1,
			 row    => $self -> view -> product -> format_products($self -> read_products_table),
		 }
		);
	close OUT;

	print "Saved $page_name. \n";

} # End of products_as_html.

# -----------------------------------------------

sub read_orders_table
{
	my($self)     = @_;
	my $order_set = $self -> db -> order -> get_orders;

	my(@order);

	while (my $order = $order_set -> next)
	{
		push @order, $self -> db -> order -> inflate_order($order);
	}

	return [@order];

} # End of read_orders_table.

# -----------------------------------------------

sub read_products_table
{
	my($self)       = @_;
	my $product_set = $self -> db -> product -> get_products;

	my(@product);

	while (my $product = $product_set -> next)
	{
		push @product, $self -> db -> product -> inflate_product($product);
	}

	return [@product];

} # End of read_products_table.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Database::Export> - Basic shopping cart

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

See scripts/export.orders.as.html.pl and scripts/export.products.as.html.pl.

=head1 Methods

=head2 orders_as_html()

Outputs each order using export.order.page.tx, and outputs an index using export.order.index.page.tx.

The location of these templates is given by 'template_path' in the config file.

The output directory is given by the 'order_html_path' in the config file.

Returns nothing.

=head2 products_as_html()

Similar to orders_as_html(), except it uses basic.table.tx, and outputs all products to one (1) HTML table.

Returns nothing.

=head2 read_orders_table()

Returns an arrayref of orders, each inflated using L<Business::Cart::Generic::Database::Order/inflate_order()>.

=head2 read_products_table()

Returns an arrayref of products, each inflated using L<Business::Cart::Generic::Database::Product/inflate_product()>.

=head1 TODO

Add a verbose command line switch, to enable the user to silence prints when exporting orders and products.

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
