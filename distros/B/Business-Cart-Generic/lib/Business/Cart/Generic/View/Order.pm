package Business::Cart::Generic::View::Order;

use strict;
use warnings;

use JSON::XS;

use Moose;

use Text::Xslate 'mark_raw';

extends 'Business::Cart::Generic::View::Base';

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub build_order_html
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'build_order_html()');

	# Use config to get some defaults.

	my($config) = $self -> config;

	# Use product table to get default (lowest) product id when products are ordered by name.

	my(@product2id)        = $self -> db -> schema -> resultset('Product') -> search({}, {columns => [qw/name id/], order_by => 'name'});
	my($zone_map, $min_id) = $self -> db -> get_special_id2name_map('Zone', 'country_id', $$config{default_country_id});
	my($zone_menu)         = $self -> build_special_select($zone_map, $$config{default_zone_id}, 'zone_id');

	# Make YUI happy by turning the HTML into 1 long line.

	my($html) = $self -> templater -> render
		(
		 'online.order.page.tx',
		 { # TODO Default billing etc addresses. Default customer.
			 billing_address_menu  => mark_raw($self -> build_select('StreetAddress', 1, 'billing_address_id', [qw/street_1 name postcode/]) ),
			 country_menu          => mark_raw($self -> build_select('Country', $$config{default_country_id}, 'country_id', [qw/name/], "change_country(country_id.options[country_id.selectedIndex].value)") ),
			 customer_address_menu => mark_raw($self -> build_select('StreetAddress', 2, 'customer_address_id', [qw/street_1 name postcode/]) ),
			 customer_name_menu    => mark_raw($self -> build_select('Customer', 1) ),
			 delivery_address_menu => mark_raw($self -> build_select('StreetAddress', 3, 'delivery_address_id', [qw/street_1 name postcode/]) ),
			 payment_method_menu   => mark_raw($self -> build_select('PaymentMethod', 1, 'payment_method_id') ),
			 product_menu          => mark_raw($self -> build_select('Product', $product2id[0] -> id, 'product_id', [qw/name description price currency_id/]) ),
			 sid                   => $self -> db -> session -> id,
			 tax_class_menu        => mark_raw($self -> build_select('TaxClass', $$config{default_tax_class_id}, 'tax_class_id') ),
			 zone_menu             => mark_raw($zone_menu),
		 }
		);
	$html =~ s/\n//g;

	return $html;

} # End of build_order_html.

# -----------------------------------------------

sub build_head_js
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'build_head_js()');

	return $self -> templater -> render
		(
		 'online.order.page.js',
		 {
			 sid => $self -> db -> session -> id,
		 }
		);

} # End of build_head_js.

# -----------------------------------------------

sub cancel_order
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'cancel_order()');

	my($order_session) = $self -> db -> session -> param('order');
	my($message)       = $$order_session{item_count} ? 'Your order has been cancelled' : 'Your cart is empty';
	my($output)        =
	{
		clear_cart  => 'Yes',
		content     => qq|<span class="red">$message</span>|,
		div_name    => 'order_message_div',
		order_count => 0,
	};

	return JSON::XS -> new -> utf8 -> encode($output);

} # End of cancel_order.

# -----------------------------------------------

sub change_country
{
	my($self, $country_id) = @_;

	$self -> db -> logger -> log(debug => "change_country($country_id)");

	my($zone_map, $min_id) = $self -> db -> get_special_id2name_map('Zone', 'country_id', $country_id);
	my($config)            = $self -> config;

	if ($country_id == $$config{default_country_id})
	{
		$min_id = $$config{default_zone_id};
	}

	return JSON::XS -> new -> utf8 -> encode({menu => $self -> build_special_select($zone_map, $min_id, 'zone_id')});

} # End of change_country.

# -----------------------------------------------

sub checkout
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'checkout()');

	my($order_session) = $self -> db -> session -> param('order');
	my($message)       = $$order_session{item_count} ? 'You have checked out' : 'Your cart is empty';
	my($output)        =
	{
		clear_cart  => 'No',
		content     => qq|<span class="red">$message</span>|,
		div_name    => 'order_message_div',
		order_count => 0,
	};

	return JSON::XS -> new -> utf8 -> encode($output);

} # End of checkout.

# -----------------------------------------------

sub display
{
	my($self, $order, $action, $order_session) = @_;

	$self -> db -> logger -> log(debug => 'display()');

	my($currency);
	my($value);

	my($count)       = 0;
	my($detail)      = $self -> db -> order -> inflate_order($order);
	my($total_price) = 0;
	my($item)        =
		[map
		 {
			 $count++;

			 $currency    = $self -> db -> schema -> resultset('Currency') -> search({id => $$_{currency_id} },{}) -> single;
			 $value       = $$_{price} * $$_{quantity};
			 $total_price += $value;

			 {
				 action      => qq|<button id="remove_from_cart_$count" onclick="remove_item($$_{order_id}, $$_{item_id})">Remove from cart</button>|,
				 name        => $$_{description} ? "$$_{name}, $$_{description}" : $$_{name},
				 price       => $self -> db -> format_amount($$_{price}, $currency),
				 quantity    => $$_{quantity},
				 tax_rate    => $$_{tax_rate},
				 total_price => $self -> db -> format_amount($value, $currency),
			 }
		 } @{$$detail{item} }
		];

	push @$item,
	{
		action   => '',
		name     => 'Total',
		price    => '-',
		quantity => '-',
		tax_rate => '-',
		total_price => $self -> db -> format_amount($total_price, $currency),
	};

	my($output) =
	{
		clear_cart  => 'No',
		content     => $item,
		div_name    => 'order_result_div',
		order_count => $action eq 'Add' ? $$order_session{order_count} : 0,
	};

	return JSON::XS -> new -> utf8 -> encode($output);

} # End of display.

# -----------------------------------------------

sub format_search_order
{
	my($self, $order) = @_;

	$self -> db -> logger -> log(debug => "format_search_order(...)");

	my($id) = $$order{id};

	my(@row);

	push @row,
	[
	 {td => "Order #:$id"},
	];

	push @row,
	[
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	];

	push @row,
	[
	 {td => 'Customer:'},
	 {td => 'Customer address:'},
	];

	# Warning: These hash keys are faked, just to work with the following loop.

	my(%extra) =
	(
	 street_1     => "$$order{customer}{title} $$order{customer}{name}",
	 locality     => '',
	 zone_name    => '',
	 country_name => '',
	);

	for my $line (qw/street_1 locality zone_name country_name/)
	{
		push @row,
		[
		 {td => $extra{$line} },
		 {td => $$order{customer_address}{$line} },
		];
	};

	push @row,
	[
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	];

	push @row,
	[
	 {td => 'Order:'},
	 {td => 'Delivery address:'},
	];

	# Warning: These hash keys are faked, just to work with the following loop.

	%extra =
	(
	 street_1     => "Added: $$order{date_added}",
	 locality     => "Completed: $$order{date_completed}",
	 zone_name    => '',
	 country_name => "Payment method: $$order{payment_method}",
	);

	for my $line (qw/street_1 locality zone_name country_name/)
	{
		push @row,
		[
		 {td => $extra{$line} },
		 {td => $$order{delivery_address}{$line} },
		];
	};

	push @row,
	[
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	];

	push @row,
	[
	 {td => 'Items:'},
	];

	push @row,
	[
	 {td => 'Name'},
	 {td => 'Price'},
	 {td => 'Quantity'},
	 {td => 'Tax rate'},
	 {td => 'Total price'},
	 {td => 'Total tax'},
	];

	# Warning: $currency is used after the loop.

	my($currency);
	my($value);

	for my $item (@{$$order{item} })
	{
		$currency = $self -> schema -> resultset('Currency') -> search({id => $$item{currency_id}}) -> single;
		$value    = $$item{quantity} * $$item{price};

		push @row,
		[
		 {td => $$item{name} },
		 {td => $self -> db -> format_amount($$item{price}, $currency)},
		 {td => $$item{quantity} },
		 {td => $$item{tax_rate} },
		 {td => $self -> db -> format_amount($value, $currency)},
		 {td => $self -> db -> format_amount($value * $$item{tax_rate}, $currency)},
		];
	}

	push @row,
	[
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	];

	push @row,
	[
	 {td => 'Totals:'},
	 {td => ''},
	 {td => $$order{total_quantity} },
	 {td => ''},
	 {td => $self -> db -> format_amount($$order{total_price}, $currency)},
	 {td => $self -> db -> format_amount($$order{total_tax}, $currency)},
	];

	push @row,
	[
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	 {td => mark_raw('<hr />')},
	];

	return \@row;

} # End of format_search_order.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::View::Order> - Basic shopping cart

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

C<new()> is called as C<< my($obj) = Business::Cart::Generic::View::Order -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::View::Order>. See L<Business::Cart::Generic::View>.

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

These keys are also getter-type methods.

=head1 Methods

=head2 build_order_html()

Returns a block of HTML for the order form.

=head2 build_head_js()

Returns a block of Javascript for insertion into the web page's head, and for use by the order form.

=head2 cancel_order()

Returns a JSON and utf8 encoded block of text suitable for sending to the client when an order is cancelled.

=head2 change_country($country_id)

Returns a JSON and utf8 encoded block of HTML for a select statement, of zones for the given country,
suitable for sending to the client.

=head2 checkout()

Returns a JSON and utf8 encoded block of text suitable for sending to the client when a user clicks [Checkout].

=head2 config()

Returns a hashref.

=head2 db()

Returns an object of type L<Business::Cart::Generic::Database>.

=head2 display($order, $action, $order_session)

Returns a JSON and utf8 encoded block of HTML for the shopping cart, suitable for sending to the client.

See online.order.page.js and the prepare_order_form() function in that file.

=head2 format_search_order($order)

$order is a hashref as returned by L<Business::Cart::Generic::Database::Order/inflate_order()>.

Returns a set of HTML table rows. This data is passed to L<Business::Cart::Generic::Search/display()>.

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
