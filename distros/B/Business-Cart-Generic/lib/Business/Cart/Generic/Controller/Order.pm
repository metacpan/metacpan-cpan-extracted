package Business::Cart::Generic::Controller::Order;

use parent 'Business::Cart::Generic::Controller';
use strict;
use warnings;

use Business::Cart::Generic::Util::Validator;

use Try::Tiny;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '0.85';

# -----------------------------------------------

sub add_to_cart
{
	my($self) = @_;

	$self -> log(debug => 'add_to_cart()');

	my($message);
	my($order);

	try
	{
		($order, $message) = $self -> param('db') -> connector -> txn(fixup => sub{$self -> add_to_cart_txn_1});
	}
	catch
	{
		$message = $self -> param('templater') -> render('online.order.error.tx', {});
		$message = $self -> param('view') -> format_errors({'Unable to add to cart' => [$message]});
	};

	if (! $message)
	{
		$self -> log(debug => 'Order data is valid');

		try
		{
			$message = $self -> param('db') -> connector -> txn(fixup => sub{$self -> add_to_cart_txn_2($order)});
		}
		catch
		{
			$message = $self -> param('templater') -> render('online.order.error.tx', {});
			$message = $self -> param('view') -> format_errors({'Unable to add to cart' => [$message]});
		};
	}

	return $message;

} # End of add_to_cart.

# -----------------------------------------------

sub add_to_cart_txn_1
{
	my($self) = @_;

	$self -> log(debug => 'add_to_cart_txn_1()');

	my($order) = Business::Cart::Generic::Util::Validator -> new
	(
	 db     => $self -> param('db'),
	 query  => $self -> query,
	) -> validate_order;

	my($message);

	if ($$order{_rejects})
	{
		$self -> log(debug => 'Order data is not valid');

		$message = $self -> param('view') -> format_errors
			($$order{_rejects}{product}
			 ? {product => ['Unknown product, or quantity 0, or quantity ordered > quantity on hand']}
			 : $$order{_rejects});
	}

	return ($order, $message);

} # End of add_to_cart_txn_1.

# -----------------------------------------------

sub add_to_cart_txn_2
{
	my($self, $order) = @_;

	$self -> log(debug => 'add_to_cart_txn_2()');

	my($order_session) = $self -> param('db') -> connector -> txn(fixup => sub{$self -> param('db') -> order -> add_to_cart($order)});

	$order = $self -> param('db') -> order -> get_orders({'me.id' => $$order{id} });

	return $self -> param('view') -> order -> display($order -> single, 'Add', $order_session);

} # End of add_to_cart_txn_2.

# -----------------------------------------------

sub cancel_order
{
	my($self) = @_;

	$self -> log(debug => 'cancel_order()');

	my($message);

	try
	{
		$message = $self -> param('db') -> connector -> txn(fixup => sub{$self -> cancel_order_txn});
	}
	catch
	{
		$message = $self -> param('templater') -> render('online.order.error.tx', {});
		$message = $self -> param('view') -> format_errors({'Unable to cancel order' => [$message]});
	};

	return $message;

} # End of cancel_order.

# -----------------------------------------------

sub cancel_order_txn
{
	my($self) = @_;

	$self -> log(debug => 'cancel_order_txn()');

	$self -> param('db') -> connector -> txn(fixup => sub{$self -> param('db') -> order -> cancel_order});

	return $self -> param('view') -> order -> cancel_order;

} # End of cancel_order_txn.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add_to_cart cancel_order change_country checkout remove_from_cart/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub change_country
{
	my($self) = @_;

	$self -> log(debug => 'change_country()');

	# TODO Validate $country_id.

	my($country_id) = $self -> query -> param('country_id');

	my($message);

	try
	{
		$message = $self -> param('view') -> order -> change_country($country_id);
	}
	catch
	{
		$message = $self -> param('templater') -> render('online.order.error.tx', {});
		$message = $self -> param('view') -> format_errors({'Unable to change country' => [$message]});
	};

	return $message;

} # End of change_country.

# -----------------------------------------------

sub checkout
{
	my($self) = @_;

	$self -> log(debug => 'checkout()');

	my($message);

	try
	{
		$message = $self -> param('db') -> connector -> txn(fixup => sub{$self -> checkout_txn});
	}
	catch
	{
		$message = $self -> param('templater') -> render('online.order.error.tx', {});
		$message = $self -> param('view') -> format_errors({'Unable to checkout' => [$message]});
	};

	return $message;

} # End of checkout.

# -----------------------------------------------

sub checkout_txn
{
	my($self) = @_;

	$self -> log(debug => 'checkout_txn()');

	$self -> param('db') -> order -> checkout;

	my($message) = $self -> param('view') -> order -> checkout;

	# Note: This must follow the call to view checkout, since the view code
	# checks the item_count in the session to determine which msg to display.

	$self -> param('db') -> reset_order;
	$self -> param('db') -> increment_order_count;

	return $message;

} # End of checkout_txn.

# -----------------------------------------------

sub remove_from_cart
{
	my($self) = @_;

	$self -> log(debug => 'remove_from_cart()');

	my($message);

	try
	{
		$message = $self -> param('db') -> connector -> txn(fixup => sub{$self -> remove_from_cart_txn});
	}
	catch
	{
		$message = $self -> param('templater') -> render('online.order.error.tx', {});
		$message = $self -> param('view') -> format_errors({'Unable to remove from cart' => [$message]});
	}

	return $message;

} # End of remove_from_cart.

# -----------------------------------------------

sub remove_from_cart_txn
{
	my($self) = @_;

	$self -> log(debug => 'remove_from_cart_txn()');

	my($order_id) = $self -> query -> param('order_id');
	my($item_id)  = $self -> query -> param('item_id');

	$self -> param('db') -> order -> remove_from_cart($order_id, $item_id);

	my($order_session) = $self -> param('db') -> session -> param('order');

	my($message);

	if ($$order_session{item_count} == 0)
	{
		$message = $self -> param('view') -> format_note({'Note' => ['All items removed from cart']});
	}
	else
	{
		my($order) = $self -> param('db') -> order -> get_orders({'me.id' => $order_id});
		$message   = $self -> param('view') -> order -> display($order -> single, 'Remove', $order_session);
	}

	return $message;

} # End of remove_from_cart_txn.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Controller::Order> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This is a sub-class of L<Business::Cart::Generic::Controller>.

=head2 Using new()

This class is never used stand-alone. However, one of its run modes is run automatically when the user clicks
one of the submit buttons on the Order form. See generic.cart.cgi or generic.cart.psgi and
also online.order.page.js for statements like var request = Y.io("/Order/checkout", cfg).

=head1 Methods

All buttons mentioned here are on the Order form.

=head2 add_to_cart()

Responds to an AJAX request when the user clicks on the [Add to cart] button.

Returns a message which is sent to the client.

=head2 add_to_cart_txn_1() and add_to_cart_txn_2()

Helpers for add_to_cart(). Never called directly.

=head2 cancel_order()

Responds to an AJAX request when the user clicks on the [Cancel order] button.

Returns a message which is sent to the client.

=head2 cancel_order_txn()

Helper for cancel_order(). Never called directly.

=head2 cgiapp_init()

Called automatically, as is the parent's cgiapp_init(), to specify the names of run modes.

=head2 change_country()

Responds when the user changes the currently selected country on the country menu. That menu has an onchange
event handler. See online.order.page.js for that handler. The handler is attached to the menu in L<Business::Cart::Generic::View::Order>.

=head2 checkout()

Responds to an AJAX request when the user clicks on the [Checkout] button.

Returns a message which is sent to the client.

=head2 checkout_txn()

Helper for checkout(). Never called directly.

=head2 remove_from_cart()

Responds to an AJAX request when the user clicks on the [Remove from cart] button.

Returns a message which is sent to the client.

=head2 remove_from_cart_txn()

Helper for remove_from_cart(). Never called directly.

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
