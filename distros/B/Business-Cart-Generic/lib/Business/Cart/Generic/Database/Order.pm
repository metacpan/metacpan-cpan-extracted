package Business::Cart::Generic::Database::Order;

use strict;
use warnings;

use Moose;

extends 'Business::Cart::Generic::Database::Base';

use namespace::autoclean;

our $VERSION = '0.85';

# --------------------------------------------------

sub add_to_cart
{
	my($self, $order) = @_;

	$self -> db -> logger -> log(debug => 'add_to_cart()');

	# Note: save_order() sets $$order{id}, and both
	# save_order() and save_order_history() use $$order{status_id}.

	my($order_session) = $self -> db -> session -> param('order');
	my(@status2id)     = $self -> schema -> resultset('OrderStatuse') -> search({}, {columns => [qw/name id/]});
	my(%status2id)     = map{($_ -> name, $_ -> id)} @status2id;
	my($status)        = 'Processing';
	$$order{status_id} = $status2id{$status};

	# Is it a new order?

	if ($$order_session{item_count} == 0)
	{
		$self -> save_order($order);

		$$order_session{id} = $$order{id};
	}
	else
	{
		$$order{id} = $$order_session{id};
	}

	$$order_session{item_id} = $$order{item_id} = $self -> save_order_item($order);

	$self -> save_order_history($order);

	$$order_session{item_count}++;

	$self -> db -> session -> param(order => $order_session);
	$self -> db -> logger -> log(info => "Order item saved. id: $$order{id}. item id: $$order{item_id}. item count: $$order_session{item_count}");

	return $order_session;

} # End of add_to_cart.

# --------------------------------------------------

sub cancel_order
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'cancel_order()');

	my($order_session) = $self -> db -> session -> param('order');

	$self -> schema -> resultset('OrderHistory') -> search({order_id => $$order_session{id} }) -> delete;
	$self -> schema -> resultset('OrderItem') -> search({order_id => $$order_session{id} }) -> delete;
	$self -> schema -> resultset('Order') -> search({id => $$order_session{id} }) -> delete;
	$self -> db -> logger -> log(info => "Order cancelled: id: $$order_session{id}");
	$self -> db -> reset_order;

} # End of cancel_order.

# --------------------------------------------------

sub checkout
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'checkout()');

	my($order_session)          = $self -> db -> session -> param('order');
	my($order_db)               = $self -> schema -> resultset('Order') -> search({id => $$order_session{id} }) -> single;
	my($order_inflated)         = $self -> inflate_order($order_db);
	my(@status2id)              = $self -> schema -> resultset('OrderStatuse') -> search({}, {columns => [qw/name id/]});
	my(%status2id)              = map{($_ -> name, $_ -> id)} @status2id;
	$$order_inflated{status}    = 'Checked out';
	$$order_inflated{status_id} = $status2id{$$order_inflated{status} };

	my($option);
	my($product);

	for my $item (@{$$order_inflated{item} })
	{
		$self -> db -> logger -> log(debug => "Updating product. id: $$item{product_id}");

		$product = $self -> schema -> resultset('Product') -> search({id => $$item{product_id} }) -> single;
		$option  =
		{
			quantity_on_hand => $product -> quantity_on_hand - $$item{quantity},
			quantity_ordered => $product -> quantity_ordered + $$item{quantity},
		};

		$product -> update($option);
	}

	$self -> db -> logger -> log(debug => "Updating order. id: $$order_session{id}");

	$option =
	{
		date_completed  => \'now()',
		date_modified   => \'now()',
		order_status_id => $$order_inflated{status_id},
	};

	$order_db -> update($option);

	# Note: save_order_history() inserts item_id into the comment field in the order_history table.

	$$order_inflated{item_id} = $$order_session{item_id};

	$self -> save_order_history($order_inflated);

} # End of checkout.

# --------------------------------------------------

sub get_orders
{
	my($self, $limit) = @_;
	$limit ||= {};

	$self -> db -> logger -> log(debug => 'get_orders()');

	return scalar $self -> schema -> resultset('Order') -> search
		(
		 $limit,
		 {
			 join     => [qw/billing_address customer customer_address delivery_address order_status payment_method/],
			 order_by => [qw/me.date_added/],
		 }
		);

} # End of get_orders.

# --------------------------------------------------

sub inflate_order
{
	my($self, $order) = @_;

	$self -> db -> logger -> log(debug => 'inflate_order()');

	my($id)      = $order -> id;
	my $item_set = $self -> schema -> resultset('OrderItem') -> search
		(
		 {
			 order_id => $id
		 },
		 {
			 join     => [qw/product/],
			 order_by => [qw/product.name/],
		 }
		);
	my(%total) =
		(
		 price    => 0,
		 quantity => 0,
		 tax      => 0,
		);

	my(@item);
	my($value);

	while (my $item = $item_set -> next)
	{
		$value           = $item -> quantity * $item -> price;
		$total{price}    += $value;
		$total{quantity} += $item -> quantity;
		$total{tax}      += $value * $item -> tax_rate;

		push @item,
		{
			currency_id => $item -> product -> currency_id,
			description => $item -> product -> description,
			item_id     => $item -> id,
			name        => $item -> name,
			order_id    => $item -> order_id,
			price       => $item -> price,
			product_id  => $item -> product_id,
			quantity    => $item -> quantity,
			tax_rate    => $item -> tax_rate,
		};
	}

	return
	{
		billing_address =>
		{
			country_name => $order -> billing_address -> country -> name,
			locality     => $order -> billing_address -> locality,
			street_1     => $order -> billing_address -> street_1,
			zone_name    => $order -> billing_address -> zone -> name,
		},
		customer =>
		{
			name  => $order -> customer -> name,
			title => $order -> customer -> title -> name,
		},
		customer_address =>
		{
			country_name => $order -> customer_address -> country -> name,
			locality     => $order -> customer_address -> locality,
			street_1     => $order -> customer_address -> street_1,
			zone_name    => $order -> customer_address -> zone -> name,
		},
		delivery_address =>
		{
			country_name => $order -> delivery_address -> country -> name,
			locality     => $order -> delivery_address -> locality,
			street_1     => $order -> delivery_address -> street_1,
			zone_name    => $order -> delivery_address -> zone -> name,
		},
		date_added     => $order -> date_added,
		date_completed => $order -> date_completed,
		id             => $id,
		item           => [@item],
		order_status   => $order -> order_status -> name,
		payment_method => $order -> payment_method -> name,
		total_price    => $total{price},
		total_quantity => $total{quantity},
		total_tax      => $total{tax},
	};

} # End of inflate_order.

# --------------------------------------------------

sub remove_from_cart
{
	my($self, $order_id, $item_id) = @_;

	$self -> db -> logger -> log(debug => "remove_from_cart($order_id, $item_id)");

	$self -> schema -> resultset('OrderItem') -> search({id => $item_id}) -> delete;

	if ($self -> db -> decrement_order_items($order_id) == 0)
	{
		$self -> cancel_order;
	}

} # End of remove_from_cart.

# --------------------------------------------------

sub save_order
{
	my($self, $order) = @_;

	$self -> db -> logger -> log(debug => 'save_order()');

	my($rs)     = $self -> schema -> resultset('Order');
	my($result) = $rs -> create
		({
			billing_address_id  => $$order{billing_address_id},
			customer_address_id => $$order{customer_address_id},
			customer_id         => $$order{customer_id},
			date_added          => \'now()',
			date_completed      => \'now()',
			date_modified       => \'now()',
			delivery_address_id => $$order{delivery_address_id},
			order_status_id     => $$order{status_id},
			payment_method_id   => $$order{payment_method_id},
		});
	my($fix_quote) = \'now()';
	$$order{id}    = $result -> id;

} # End of save_order.

# --------------------------------------------------

sub save_order_history
{
	my($self, $order) = @_;

	$self -> db -> logger -> log(debug => 'save_order_history()');

	my($rs)          = $self -> schema -> resultset('OrderHistory');
	my(@yesno2id)    = $self -> schema -> resultset('YesNo') -> search({}, {columns => [qw/name id/]});
	my(%yesno2id)    = map{($_ -> name, $_ -> id)} @yesno2id;
	my($notified_id) = $yesno2id{'No'};
	my($result)      = $rs -> create
		({
			comment              => "item_id: $$order{item_id}",
			date_added           => \'now()',
			date_modified        => \'now()',
			customer_notified_id => $notified_id,
			order_id             => $$order{id},
			order_status_id      => $$order{status_id},
		 });

} # End of save_order_history.

# --------------------------------------------------

sub save_order_item
{
	my($self, $order) = @_;

	$self -> db -> logger -> log(debug => 'save_order_item()');

	my($product)  = $self -> schema -> resultset('Product') -> search({id => $$order{product_id} },{}) -> single;
	my($tax_rate) = $self -> schema -> resultset('TaxRate') -> search({tax_class_id => $$order{tax_class_id}, zone_id => $$order{zone_id} }, {}) -> single;
	my($rs)       = $self -> schema -> resultset('OrderItem');
	my($result)   = $rs -> create
		({
			model      => $product -> model,
			name       => $product -> name,
			order_id   => $$order{id},
			price      => $product -> price,
			product_id => $$order{product_id},
			quantity   => $$order{quantity},
			tax_rate   => $tax_rate -> rate,
			upper_name => uc $product -> name,
		 });

	return $result -> id;

} # End of save_order_item.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Database::Order> - Basic shopping cart

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

C<new()> is called as C<< my($obj) = Business::Cart::Generic::Database::Order -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::Database::Order>. See L<Business::Cart::Generic::Database>.

Key-value pairs accepted in the parameter list:

=over 4

=item o db => $db

Takes an object of type L<Business::Cart::Generic::Database>.

This key => value pair is mandatory.

=item o schema => $schema

Takes a L<DBIx::Class> schema object.

This value is provided by the parent, L<Business::Cart::Generic::Database::Base>.

=back

These keys are also getter-type methods.

=head1 Methods

=head2 add_to_cart($order)

Add an item to the cart.

$order is a hashref returned by L<Business::Cart::Generic::Util::Validator>.

Returns the order hashref from the session object.

This latter hashref is discussed in the FAQ in L<Business::Cart::Generic>.
The code is in L<Business::Cart::Generic::Database/reset_order()>.

=head2 cancel_order()

Cancel the order whose id is in the order hashref in the session object.

Returns nothing.

=head2 checkout()

Wrap up the order by calculating quantities on hand per item, and updating the order history.

Returns nothing.

=head2 get_orders($limit)

Get order item objects from the orders table.

These items are of type L<DBIx::Class::Row>.

Limit defaults to {}, and can be used to get 1 order by - e.g. - setting it to {'me.id' => $order_id}.

The orders table is joined with these tables:

=over 4

=item o The billing_address

I.e. the street_addresses table.

=item o The customers table

=item o The customer_address

I.e. the street_addresses table.

=item o The delivery_address

I.e. the street_addresses table.

=item o The order_statuses table

=item o The payment_methods table

=back

=head2 inflate_order($order)

$order is of type L<DBIx::Class::Row>.

Returns a hashref with these keys:

=over 4

=item o billing_address

This is a hashref with these keys:

=over 4

=item o country_name

=item o locality

=item o street_1

=item o zone_name

=back

The values are all strings.

=item o customer

This is a hashref with these keys:

=over 4

=item o name

=item o title

=back

The values are all strings.

=item o customer_address

This is a hashref with these keys:

=over 4

=item o country_name

=item o locality

=item o street_1

=item o zone_name

=back

The values are all strings.

=item o delivery_address

This is a hashref with these keys:

=over 4

=item o country_name

=item o locality

=item o street_1

=item o zone_name

=back

The values are all strings.

=item o date_added

This is a string like '2011-05-10 10:48:53'.

=item o date_completed

This is a string like '2011-05-10 10:48:53'.

=item o id

This is the order's primary key in the orders table.

=item o item

This is an array ref of item hashrefs, with these keys:

=over 4

=item o currency_id

This is the currency's primary key in the currencies table.

=item o description

This is a string from the products table.

=item o item_id

This is the item's primary key in the items table.

=item o name

This is a string from the products table.

=item o order_id

This is the order's primary key in the orders table.

=item o price

This is a float from the products table.

=item o product_id

This is the product's primary key in the products table.

=item o quantity

This is an integer from the items table.

=item o tax_rate

This is a float from the products table.

=back

=item o order_status

This is a string from the order_statuses table.

=item o payment_method

This is a string from the payment_methods table.

=item o total_price

This is a sum over all items.

=item o total_quantity

This is a sum over all items.

=item o total_tax

This is a sum over all items.

=back

=head2 remove_from_cart($order_id, $item_id)

Remove an item from the cart.

$order_id is the primary key in the orders table.

$item_id is the primary key in the items table.

=head2 save_order($order)

Called by add_to_cart().

$order is a hashref returned by L<Business::Cart::Generic::Util::Validator>.

Returns nothing.

=head2 save_order_history($order)

Called by add_to_cart().

$order is a hashref returned by L<Business::Cart::Generic::Util::Validator>.

Returns nothing.

=head2 save_order_item($order)

Called by add_to_cart().

$order is a hashref returned by L<Business::Cart::Generic::Util::Validator>.

Returns the primary key in the items table of the newly-inserted item.

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
