package Business::Cart::Generic::Database;

use strict;
use warnings;

use Business::Cart::Generic::Database::Order;
use Business::Cart::Generic::Database::Product;
use Business::Cart::Generic::Database::Search;
use Business::Cart::Generic::Schema;

use Data::Session;

use DBIx::Admin::CreateTable;
use DBIx::Connector;

use List::Util 'min';

use Moose;

extends 'Business::Cart::Generic::Base';

has online =>
(
 default  => 1,
 is       => 'ro',
 isa      => 'Int',
 required => 0,
);

has order =>
(
 is  => 'rw',
 isa => 'Business::Cart::Generic::Database::Order',
 required => 0,
);

has product =>
(
 is  => 'rw',
 isa => 'Business::Cart::Generic::Database::Product',
 required => 0,
);

has query =>
(
 is  => 'ro',
 isa => 'Any',
 required => 1,
);

has schema =>
(
 is  => 'rw',
 isa => 'Business::Cart::Generic::Schema',
 required => 0,
);

has search =>
(
 is  => 'rw',
 isa => 'Business::Cart::Generic::Database::Search',
 required => 0,
);

has session =>
(
 is  => 'rw',
 isa => 'Data::Session',
 required => 0,
);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = $self -> config;
	my($attr)   = {AutoCommit => $$config{AutoCommit}, RaiseError => $$config{RaiseError} };

	if ( ($$config{dsn} =~ /SQLite/i) && $$config{sqlite_unicode})
	{
		$$attr{sqlite_unicode} = 1;
	}

	$self -> connector(DBIx::Connector -> new($$config{dsn}, $$config{username}, $$config{password}, $attr) );
	$self -> schema
		(
		 Business::Cart::Generic::Schema -> connect(sub{return $self -> connector -> dbh})
		);

	if ($$config{dsn} =~ /SQLite/i)
	{
		$self -> connector -> dbh -> do('PRAGMA foreign_keys = ON');
	}

	# populate.tables.pl and place.orders.pl call us with online => 0.

	$self -> set_up_session($config) if ($self -> online);

	# Note: A database object is created before a session object, so
	# we can't pass the session object to any other objects. Not that
	# we want to. Just use $obj -> db -> session...

	$self -> order
		(
		 Business::Cart::Generic::Database::Order -> new
		 (
		  db => $self,
		 )
		);

	$self -> product
		(
		 Business::Cart::Generic::Database::Product -> new
		 (
		  db => $self,
		 )
		);

	$self -> search
		(
		 Business::Cart::Generic::Database::Search -> new
		 (
		  db => $self,
		 )
		);

	return $self;

}	# End of BUILD.

# --------------------------------------------------

sub decrement_order_items
{
	my($self) = @_;

	$self -> logger -> log(debug => 'decrement_order_items()');

	my($order_session) = $self -> session -> param('order');

	$$order_session{item_count}--;

	$self -> session -> param(order => $order_session);

	return $$order_session{item_count};

} # End of decrement_order_items.

# --------------------------------------------------

sub get_id2name_map
{
	my($self, $class_name, $column_list) = @_;
	my(@rs)       = $self -> schema -> resultset($class_name) -> search({}, {columns => ['id', @$column_list]});
	@$column_list = grep{! /currency_id/} @$column_list;

	my($currency, $column);
	my(%map);
	my(@s);

	for my $rs (@rs)
	{
		if ($class_name eq 'Product')
		{
			$currency = $self -> schema -> resultset('Currency') -> search({id => $rs -> currency_id}, {}) -> single;
		}

		@s = ();

		for $column (@$column_list)
		{
			if ($column eq 'price')
			{
				push @s, $self -> format_amount($rs -> price, $currency);
			}
			elsif ($rs -> $column ne '')
			{
				push @s, $rs -> $column;
			}
		}

		$map{$rs -> id} = join(', ', @s);
	}

	return {%map};

} # End of get_id2name_map.

# --------------------------------------------------

sub get_special_id2name_map
{
	my($self, $class_name, $constraint_name, $constraint_value) = @_;

	my($map)    = {map{($_ -> id, $_ -> name)} $self -> schema -> resultset($class_name) -> search({$constraint_name => $constraint_value}, {columns => [qw/id name/]})};
	my($min_id) = min keys %$map;

	return ($map, $min_id);

} # End of get_special_id2name_map.

# --------------------------------------------------

sub increment_order_count
{
	my($self) = @_;

	$self -> logger -> log(debug => 'increment_order_count()');

	my($order_session) = $self -> session -> param('order');

	$$order_session{order_count}++;

	$self -> session -> param(order => $order_session);

	return $$order_session{order_count};

} # End of increment_order_count.

# --------------------------------------------------

sub reset_order
{
	my($self) = @_;

	$self -> logger -> log(debug => 'reset_order()');

	# If the CGI client (user) is a new client, then start a new order.
	# Of course, the user may not actually buy anything. We only know what
	# they're doing when they click buttons on the Order form, in which case
	# the code in *::Controller::Order will be called.
	# These fields both help us track orders and help us unwind cancelled orders.

	$self -> session -> param(order => {id => 0, item_count => 0, item_id => 0, order_count => 0});

} # End of reset_order.

# --------------------------------------------------

sub set_up_session
{
	my($self) = @_;

	$self -> logger -> log(debug => 'set_up_session()');

	my($config) = $self -> config;

	$self -> session
		(
		 Data::Session -> new
		 (
		  dbh        => $self -> connector -> dbh,
		  name       => 'sid',
		  pg_bytea   => $$config{pg_bytea} || 0,
		  pg_text    => $$config{pg_text}  || 0,
		  query      => $self -> query,
		  table_name => $$config{session_table_name},
		  type       => $$config{session_driver},
		 )
		);

	if ($Data::Session::errstr)
	{
		die $Data::Session::errstr;
	}

	if ($self -> session -> is_new)
	{
		$self -> reset_order;
	}

} # End of set_up_session.

# --------------------------------------------------

sub validate_country_id
{
	my($self, $id) = @_;

	return $self -> schema -> resultset('Country') -> search({id => $id}, {}) -> single ? 1 : 0;

} # End of validate_country_id.

# --------------------------------------------------

sub validate_customer_id
{
	my($self, $id) = @_;

	return $self -> schema -> resultset('Customer') -> search({id => $id}, {}) -> single ? 1 : 0;

} # End of validate_customer_id.

# --------------------------------------------------

sub validate_payment_method_id
{
	my($self, $id) = @_;

	return $self -> schema -> resultset('PaymentMethod') -> search({id => $id}, {}) -> single ? 1 : 0;

} # End of validate_payment_method_id.

# --------------------------------------------------

sub validate_product
{
	my($self, $id, $quantity) = @_;
	my($product) = $self -> schema -> resultset('Product') -> search({id => $id}, {}) -> single;
	my($result)  = 0;

	# max_quantity_per_order will be 24. See config/.htbusiness.cart.generic.conf.

	if ($product && ($quantity > 0) && ($quantity <= ${$self -> config}{max_quantity_per_order}) )
	{
		# We don't handle back-orders, so you can only buy what's in stock.

		$result = ($product -> quantity_on_hand >= $quantity) ? 1 : 0;
	}

	return $result;

} # End of validate_product.

# --------------------------------------------------

sub validate_street_address_id
{
	my($self, $id) = @_;

	return $self -> schema -> resultset('StreetAddress') -> search({id => $id}, {}) -> single ? 1 : 0;

} # End of validate_street_address_id.

# --------------------------------------------------

sub validate_tax_class_id
{
	my($self, $id) = @_;

	return $self -> schema -> resultset('TaxClass') -> search({id => $id}, {}) -> single ? 1 : 0;

} # End of validate_tax_class_id.

# --------------------------------------------------

sub validate_zone_id
{
	my($self, $id) = @_;

	return $self -> schema -> resultset('Zone') -> search({id => $id}, {}) -> single ? 1 : 0;

} # End of validate_zone_id.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Database> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class extends L<Business::Cart::Generic::Base>.

=head2 Using new()

C<new()> is called as C<< my($obj) = Business::Cart::Generic::Database -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::Database>.

Key-value pairs accepted in the parameter list:

=over 4

=item o online => $zero_or_one

Takes an integer.

Defaults to 1.

It is set to 0 in command line code, such as when using L<Business::Cart::Generic::Database::Import>.

This value is optional.

=item o order => $order

Takes an object of type L<Business::Cart::Generic::Database::Order>.

This value is set automatically at object construction time.

=item o product => $product

Takes an object of type L<Business::Cart::Generic::Database::Product>.

This value is set automatically at object construction time.

=item o query => $query

Takes an object of type L<CGI> or similar.

This key => value pair is mandatory.

=item o schema => $schema

Takes a L<DBIx::Class> schema object.

This value is set automatically at object construction time.

=item o search => $search

Takes an object of type L<Business::Cart::Generic::Database::Search>.

This value is set automatically at object construction time.

=item o session => $session

Takes an object of type L<Data::Session>.

This value is set automatically at object construction time when online has the value of 1 (the default).

=back

These keys are also getter-type methods.

=head1 Methods

=head2 decrement_order_items()

Decrements the count of items in the shopping cart, as stored in the session object.

Returns the item count.

=head2 get_id2name_map($class_name, $column_list)

Returns a hashref of (id => name) mappings from the table whose class is $class_name.

$column_list is an array of column names, I<excluding> 'id' (since 'id' is added automatically to the list).

If $class_name is 'Product', $column_list I<must> include 'currency_id' (since the currency is used to format the price,
if 'price' is in $column_list).

The reason for having a column list is so the output values ('name') can be a string of comma-separated values taken from
several columns in the table.

For instance, when building a drop-down menu of products (via build_select), $column_list is [qw/name description price currency_id/].

=head2 get_special_id2name_map($class_name, $constraint_name, $constraint_value)

A limited form of get_id2name_map, returning only the 'id' and 'name' columns.

Returns a list of 2 elements:

=over 4

=item o A hashref of (id => name) mappings from the table whose class is $class_name

=item o An integer which is the minimum value of id

This can be used to set the default in a drop-down HTML menu.

=back

$constraint_name is a column name from the table, and $constraint_value is the value in that column to restrict the selection to.

For instance, to get just the zones for a given country, use get_special_id2name_map('Zone', 'country_id', $country_id).

=head2 increment_order_count()

Increments the count of orders placed by the customer, as stored in the session object.

Returns the order count.

After checking out, the customer can choose a product and click [Add to item], starting a new shopping cart. This counter
tracks such activity.

=head2 reset_order()

Resets the order in the session object.

Returns nothing.

The order is a hashref, discussed in the FAQ in L<Business::Cart::Generic>.

=head2 setup_session()

Creates a new L<Data::Session> object.

Configuration parameters come from the return value of config().

If it's a new session, calls reset_order().

=head2 validate_country_id($id)

Called by L<Business::Cart::Generic::Util::Validator>.

Returns 1 of the $id is valid, else 0.

=head2 validate_customer_id($id)

Called by L<Business::Cart::Generic::Util::Validator>.

Returns 1 of the $id is valid, else 0.

=head2 validate_payment_method_id($id)

Called by L<Business::Cart::Generic::Util::Validator>.

Returns 1 of the $id is valid, else 0.

=head2 validate_product($id, $quantity)

Called by L<Business::Cart::Generic::Util::Validator>.

Returns 1 of the $id and $quantity are valid, else 0.

The $id has to be the id (primary key) of a product, and the quantity has to be both greater than 0,
and less than or equal to max_quantity_per_order from the config file.

=head2 validate_street_address_id($id)

Called by L<Business::Cart::Generic::Util::Validator>.

Returns 1 of the $id is valid, else 0.

=head2 validate_tax_class_id($id)

Called by L<Business::Cart::Generic::Util::Validator>.

Returns 1 of the $id is valid, else 0.

=head2 validate_zone_id($id)

Called by L<Business::Cart::Generic::Util::Validator>.

Returns 1 of the $id is valid, else 0.

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
