package Business::Cart::Generic::Database::Loader;

use strict;
use warnings;

use CGI;

use FindBin;

use Business::Cart::Generic::Database;

use IO::File;

use Moose;

use Perl6::Slurp;

use Text::CSV_XS;
use Text::Xslate;

use Try::Tiny;

extends 'Business::Cart::Generic::Database::Base';

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
		  online => 0,
		  query  => CGI -> new,
		 )
		);

}	# End of BUILD.

# -----------------------------------------------

sub generate_description
{
	my($self, $name, $type, $style, $color, $class, $size) = @_;

	if ($name eq '-')
	{
		$name = $type;
	}
	else
	{
		$name .= ' - ' . $type;
	}

	my(@description);

	if ($style ne '-')
	{
		push @description, $style;
	}

	if ($color ne '-')
	{
		push @description, $color;
	}

	if ($class ne '-')
	{
		push @description, $class;
	}

	if ($size ne '-')
	{
		push @description, $size;
	}

	for (1 .. $#description)
	{
		$description[$_] = lc $description[$_];
	}

	return ($name, join(', ', @description) );

} # End of generate_description.

# -----------------------------------------------

sub import_products
{
	my($self) = @_;

	$self -> connector -> txn
		(
		 fixup => sub{ $self -> populate_tables }, catch{ defined $_ ? die $_ : ''}
		);

}	# End of import_products.

# -----------------------------------------------

sub place_orders
{
	my($self) = @_;

	$self -> populate_orders_table;

}	# End of place_orders.

# -----------------------------------------------

sub populate_tables
{
	my($self) = @_;

	$self -> populate_manufacturers_table;
	$self -> populate_street_addresses_table;
	$self -> populate_customers_table;
	$self -> populate_tax_rates_table;
	$self -> populate_table('product.classes.csv', 'ProductClass');
	$self -> populate_table('product.colors.csv', 'ProductColor');
	$self -> populate_table('product.sizes.csv', 'ProductSize');
	$self -> populate_table('product.statuses.csv', 'ProductStatuse');
	$self -> populate_table('product.styles.csv', 'ProductStyle');
	$self -> populate_table('product.types.csv', 'ProductType');
	$self -> populate_products_table;

}	# End of populate_tables.

# -----------------------------------------------

sub populate_customers_table
{
	my($self)      = @_;
	my($path)      = "$FindBin::Bin/../data/customers.csv";
	my($customer)  = $self -> read_csv_file($path);
	my($rs)        = $self -> schema -> resultset('Customer');
	my(@gender2id) = $self -> schema -> resultset('Gender') -> search({}, {columns => [qw/name id/]});
	my(%gender2id) = map{($_ -> name, $_ -> id)} @gender2id;
	my(@status2id) = $self -> schema -> resultset('CustomerStatuse') -> search({}, {columns => [qw/name id/]});
	my(%status2id) = map{($_ -> name, $_ -> id)} @status2id;
	my(@title2id)  = $self -> schema -> resultset('Title') -> search({}, {columns => [qw/name id/]});
	my(%title2id)  = map{($_ -> name, $_ -> id)} @title2id;
	my(@type2id)   = $self -> schema -> resultset('CustomerType') -> search({}, {columns => [qw/name id/]});
	my(%type2id)   = map{($_ -> name, $_ -> id)} @type2id;

	my($gender_id);
	my($result);
	my($status_id);
	my($title_id, $type_id);

	for my $line (@$customer)
	{
		$gender_id = $gender2id{$$line{gender} } || die "Unknown gender: $$line{gender}";
		$status_id = $status2id{$$line{status} } || die "Unknown status: $$line{status}";
		$title_id  = $title2id{$$line{title} }   || die "Unknown title: $$line{title}";
		$type_id   = $type2id{$$line{type} }     || die "Unknown type: $$line{type}";
		$result    = $rs -> create
			({
				customer_status_id        => $status_id,
				customer_type_id          => $type_id,
				date_added                => \'now()',
				date_of_birth             => $$line{dob},
				date_modified             => \'now()',
				default_street_address_id => 1, # TODO.
				gender_id                 => $gender_id,
				given_names               => $$line{given_names},
				name                      => "$$line{given_names} $$line{surname}",
				password                  => $$line{password},
				preferred_name            => $$line{given_names},
				surname                   => $$line{surname},
				title_id                  => $title_id,
				upper_name                => uc "$$line{given_names} $$line{surname}",
				username                  => $$line{username},
			});
	}

} # End of populate_customers_table.

# -----------------------------------------------

sub populate_manufacturers_table
{
	my($self) = @_;
	my($path) = "$FindBin::Bin/../data/manufacturers.csv";
	my($data) = $self -> read_csv_file($path);
	my($rs)   = $self -> schema -> resultset('Manufacturer');

	my($result);

	for my $line (@$data)
	{
		$result = $rs -> create
			(
			 {
				 date_added    => \'now()',
				 date_modified => \'now()',
				 image         => $$line{image},
				 name          => $$line{name},
				 upper_name    => uc $$line{name},
			 }
			);
	}

} # End of populate_manufacturers_table.

# -----------------------------------------------

sub populate_order_history_table
{
	my($self, $order_id, $status_id, $notified) = @_;
	my($rs)          = $self -> schema -> resultset('OrderHistory');
	my(@yesno2id)    = $self -> schema -> resultset('YesNo') -> search({}, {columns => [qw/name id/]});
	my(%yesno2id)    = map{($_ -> name, $_ -> id)} @yesno2id;
	my($notified_id) = $yesno2id{$notified};
	my($result)      = $rs -> create
		({
			comment              => '',
			date_added           => \'now()',
			date_modified        => \'now()',
			customer_notified_id => $notified_id,
			order_id             => $order_id,
			order_status_id      => $status_id,
		 });

} # End of populate_order_history_table.

# -----------------------------------------------

sub populate_order_items_table
{
	my($self, $order_id) = @_;
	my($path)         = "$FindBin::Bin/../data/order.items.csv";
	my($order)        = $self -> read_csv_file($path);
	my($rs)           = $self -> schema -> resultset('OrderItem');
	my(@country2id)   = $self -> schema -> resultset('Country') -> search({}, {columns => [qw/name id/]});
	my(%country2id)   = map{($_ -> name, $_ -> id)} @country2id;
	my(@product2id)   = $self -> schema -> resultset('Product') -> search({}, {columns => [qw/name id/]});
	my(%product2id)   = map{($_ -> name, $_ -> id)} @product2id;
	my(@tax_class2id) = $self -> schema -> resultset('TaxClass') -> search({}, {columns => [qw/name id/]});
	my(%tax_class2id) = map{($_ -> name, $_ -> id)} @tax_class2id;

	my($country_id);
	my($product_id, $product, $product_name);
	my($result);
	my($tax_class_id, $tax_rate);
	my(@zone2id, %zone2id, $zone_id);

	for my $line (@$order)
	{
		$country_id   = $country2id{$$line{country} }     || die "Unknown country: $$line{country}";
		@zone2id      = $self -> schema -> resultset('Zone') -> search({country_id => $country_id}, {columns => [qw/code id/]});
		%zone2id      = map{($_ -> code, $_ -> id)} @zone2id;
		$zone_id      = $zone2id{$$line{zone} }           || die "Unknown zone: $$line{zone}";
		$product_id   = $product2id{$$line{name} }        || die "Unknown name: $$line{name}";
		$tax_class_id = $tax_class2id{$$line{tax_class} } || die "Unknown tax class: $$line{tax_class}";
		$product      = $self -> schema -> resultset('Product') -> search({id => $product_id}, {}) -> single;
		$product_name = $product -> name;
		$tax_rate     = $self -> schema -> resultset('TaxRate') -> search({tax_class_id => $tax_class_id, zone_id => $zone_id}, {}) -> single;
		$result       = $rs -> create
			({
				model      => $product -> model,
				name       => $product_name,
				order_id   => $order_id,
				price      => $product -> price,
				product_id => $product_id,
				quantity   => $$line{quantity},
				tax_rate   => $tax_rate -> rate,
				upper_name => uc $product_name,
			});

		$product -> quantity_on_hand($product -> quantity_on_hand - $$line{quantity});
		$product -> update;
	}

} # End of populate_order_items_table.

# -----------------------------------------------

sub populate_orders_table
{
	my($self)       = @_;
	my($path)       = "$FindBin::Bin/../data/orders.csv";
	my($order)      = $self -> read_csv_file($path);
	my($rs)         = $self -> schema -> resultset('Order');
	my(@status2id)  = $self -> schema -> resultset('OrderStatuse') -> search({}, {columns => [qw/name id/]});
	my(%status2id)  = map{($_ -> name, $_ -> id)} @status2id;
	my(@payment2id) = $self -> schema -> resultset('PaymentMethod') -> search({}, {columns => [qw/name id/]});
	my(%payment2id) = map{($_ -> name, $_ -> id)} @payment2id;
	my($count)      = 0;

	my($current_order);
	my($order_id);
	my($payment_id);
	my($result);
	my($status, $status_id);

	for my $line (@$order)
	{
		$count++;

		$payment_id = $payment2id{$$line{payment} } || die "Unknown payment: $$line{payment}";
		$status     = 'Processing';
		$status_id  = $status2id{$status}           || die "Unknown status: $status";
		$result     = $rs -> create
			({
			 billing_address_id  => $$line{billing_address_id},
			 customer_address_id => $$line{customer_address_id},
			 customer_id         => $$line{customer_id},
			 date_added          => \'now()',
			 date_completed      => \'now()',
			 date_modified       => \'now()',
			 delivery_address_id => $$line{delivery_address_id},
			 order_status_id     => $status_id,
			 payment_method_id   => $payment_id,
			});
		$order_id = $result -> id;

		# Fabricate some history for each order.

		$status    = 'Payment accepted';
		$status_id = $status2id{$status} || die "Unknown status: $status";

		$self -> populate_order_history_table($order_id, $status_id, 'No');

		# TODO: Should check quantity ordered is available,
		# or trigger a backorder if it isn't (all) available.

		$self -> populate_order_items_table($order_id);

		# Sleep so date_added is not always the same.

		sleep 1;

		$status    = 'Shipped';
		$status_id = $status2id{$status} || die "Unknown status: $status";

		$self -> populate_order_history_table($order_id, $status_id, ($count % 2) == 1 ? 'No' : 'Yes');

		if ( ($count % 2) == 1)
		{
			$status    = 'Delivered';
			$status_id = $status2id{$status} || die "Unknown status: $status";

			$self -> populate_order_history_table($order_id, $status_id, 'Yes');
		}

		$current_order = $rs -> search({id => $order_id}, {}) -> single;

		$current_order -> order_status_id($status_id);
		$current_order -> update;
	}

} # End of populate_orders_table.

# -----------------------------------------------

sub populate_products_table
{
	my($self)            = @_;
	my($path)            = "$FindBin::Bin/../data/products.csv";
	my($data)            = $self -> read_csv_file($path);
	my($rs)              = $self -> schema -> resultset('Product');
	my(@class2id)        = $self -> schema -> resultset('ProductClass') -> search({}, {columns => [qw/name id/]});
	my(%class2id)        = map{($_ -> name, $_ -> id)} @class2id;
	my(@color2id)        = $self -> schema -> resultset('ProductColor') -> search({}, {columns => [qw/name id/]});
	my(%color2id)        = map{($_ -> name, $_ -> id)} @color2id;
	my(@currency2id)     = $self -> schema -> resultset('Currency') -> search({}, {columns => [qw/code id/]});
	my(%currency2id)     = map{($_ -> code, $_ -> id)} @currency2id;
	my(@manufacturer2id) = $self -> schema -> resultset('Manufacturer') -> search({}, {columns => [qw/name id/]});
	my(%manufacturer2id) = map{($_ -> name, $_ -> id)} @manufacturer2id;
	my(@size2id)         = $self -> schema -> resultset('ProductSize') -> search({}, {columns => [qw/name id/]});
	my(%size2id)         = map{($_ -> name, $_ -> id)} @size2id;
	my(@status2id)       = $self -> schema -> resultset('ProductStatuse') -> search({}, {columns => [qw/name id/]});
	my(%status2id)       = map{($_ -> name, $_ -> id)} @status2id;
	my(@style2id)        = $self -> schema -> resultset('ProductStyle') -> search({}, {columns => [qw/name id/]});
	my(%style2id)        = map{($_ -> name, $_ -> id)} @style2id;
	my(@tax2id)          = $self -> schema -> resultset('TaxClass') -> search({}, {columns => [qw/name id/]});
	my(%tax2id)          = map{($_ -> name, $_ -> id)} @tax2id;
	my(@type2id)         = $self -> schema -> resultset('ProductType') -> search({}, {columns => [qw/name id/]});
	my(%type2id)         = map{($_ -> name, $_ -> id)} @type2id;
	my($count)           = 0;

	my($class_id, $color_id, $currency_id);
	my($description);
	my($manufacturer_id);
	my($name);
	my(@product);
	my($result);
	my($size_id, $status_id, $style_id);
	my($tax_id, $type_id);

	for my $line (@$data)
	{
		$class_id             = $class2id{$$line{class} }               || die "Unknown class: $$line{class}";
		$color_id             = $color2id{$$line{color} }               || die "Unknown color: $$line{color}";
		$currency_id          = $currency2id{$$line{currency} }         || die "Unknown currency: $$line{currency}";
		$manufacturer_id      = $manufacturer2id{$$line{manufacturer} } || die "Unknown manufacturer: $$line{manufacturer}";
		$size_id              = $size2id{$$line{size} }                 || die "Unknown size: $$line{size}";
		$status_id            = $status2id{$$line{status} }             || die "Unknown status: $$line{status}";
		$style_id             = $style2id{$$line{style} }               || die "Unknown style: $$line{style}";
		$tax_id               = $tax2id{$$line{tax} }                   || die "Unknown tax: $$line{tax}";
		$type_id              = $type2id{$$line{type} }                 || die "Unknown type: $$line{type}";
		($name, $description) = $self -> generate_description
			(
			 $$line{name}, $$line{type}, $$line{style}, $$line{color}, $$line{class}, $$line{size},
			);
		$result = $rs -> create
			(
			 {
				 currency_id       => $currency_id,
				 date_added        => \'now()',
				 date_modified     => \'now()',
				 description       => $description,
				 has_children      => 'No',                
				 manufacturer_id   => $manufacturer_id,
				 model             => sprintf('SKU-%04i', ++$count), # TODO.
				 name              => $name,
				 parent_id         => 0,
				 price             => $$line{price},
				 quantity_on_hand  => $$line{quantity},
				 quantity_ordered  => 0,   # TODO.
				 product_status_id => $status_id,
				 tax_class_id      => $tax_id,
				 upper_name        => uc $name,
				 weight            => 0, # TODO.
				 weight_class_id   => 1, # TODO.
			 }
			);
	}

} # End of populate_products_table.

# -----------------------------------------------

sub populate_street_addresses_table
{
	my($self)       = @_;
	my($path)       = "$FindBin::Bin/../data/street.addresses.csv";
	my($address)    = $self -> read_csv_file($path);
	my($rs)         = $self -> schema -> resultset('StreetAddress');
	my(@country2id) = $self -> schema -> resultset('Country') -> search({}, {columns => [qw/name id/]});
	my(%country2id) = map{($_ -> name, $_ -> id)} @country2id;
	my(@zone2id)    = $self -> schema -> resultset('Zone') -> search({}, {columns => [qw/code id/]});
	my(%zone2id)    = map{($_ -> code, $_ -> id)} @zone2id;

	my($country_id);
	my($result);
	my($zone_id);

	for my $line (@$address)
	{
		$country_id = $country2id{$$line{country} } || die "Unknown country: $$line{country}";
		$zone_id    = $zone2id{$$line{zone} }       || die "Unknown zone: $$line{zone}";
		$result     = $rs -> create
			({
			 country_id => $country_id,
			 zone_id    => $zone_id,
			 locality   => $$line{locality},
			 postcode   => $$line{postcode},
			 name       => $$line{locality},
			 street_1   => $$line{street_1},
			 street_2   => '',
			 street_3   => '',
			 street_4   => '',
			 upper_name => uc $$line{locality},
			});
	}

} # End of populate_street_addresses_table.

# -----------------------------------------------

sub populate_table
{
	my($self, $file_name, $class_name) = @_;
	my($path) = "$FindBin::Bin/../data/$file_name";
	my($data) = $self -> read_csv_file($path);
	my($rs)   = $self -> schema -> resultset($class_name);

	my($result);

	for my $line (@$data)
	{
		$result = $rs -> create
			({
			 name       => $$line{name},
			 upper_name => uc $$line{name},
			});
	}

} # End of populate_table.

# -----------------------------------------------

sub populate_tax_rates_table
{
	my($self)         = @_;
	my($path)         = "$FindBin::Bin/../data/tax.rates.csv";
	my($rate)         = $self -> read_csv_file($path);
	my($rs)           = $self -> schema -> resultset('TaxRate');
	my(@country2id)   = $self -> schema -> resultset('Country') -> search({}, {columns => [qw/name id/]});
	my(%country2id)   = map{($_ -> name, $_ -> id)} @country2id;
	my(@tax_class2id) = $self -> schema -> resultset('TaxClass') -> search({}, {columns => [qw/name id/]});
	my(%tax_class2id) = map{($_ -> name, $_ -> id)} @tax_class2id;

	my($country_id);
	my($result);
	my($tax_class_id);
	my(@zone2id, %zone2id, $zone_id);

	for my $line (@$rate)
	{
		$country_id   = $country2id{$$line{country} }     || die "Unknown country: $$line{country}";
		@zone2id      = $self -> schema -> resultset('Zone') -> search({country_id => $country_id}, {columns => [qw/code id/]});
		%zone2id      = map{($_ -> code, $_ -> id)} @zone2id;
		$tax_class_id = $tax_class2id{$$line{tax_class} } || die "Unknown tax class: $$line{tax_class}";
		$zone_id      = $zone2id{$$line{zone} }           || die "Unknown zone: $$line{zone}";
		$result       = $rs -> create
			({
			 date_added    => \'now()',
			 date_modified => \'now()',
			 description   => 'A tax rate',
			 name          => $$line{name},
			 rate          => $$line{rate},
			 tax_class_id  => $tax_class_id,
			 upper_name => uc $$line{name},
			 zone_id       => $zone_id,
			});
	}

} # End of populate_tax_rates_table.

# -----------------------------------------------

sub read_csv_file
{
	my($self, $file_name) = @_;
	my($csv) = Text::CSV_XS -> new({binary => 1});
	my($io)  = IO::File -> new($file_name, 'r');

	$csv -> column_names($csv -> getline($io) );

	return $csv -> getline_hr_all($io);

} # End of read_csv_file.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Database::Loader> - Basic shopping cart

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

See scripts/import.produces.pl and scripts/place.orders.pl.

=head1 Methods

=head2 generate_description($name, $type, $style, $color, $class, $size)

Use various fields from data/products.csv to generate a description for each product.

=head2 import_products()

Runs a db transaction to import product data.

Calls populate_tables().

Returns nothing.

=head2 place_orders()

Imports orders from data/orders.csv.

Calls populate_orders_table.

Returns nothing.

=head2 populate_tables()

Helper for import_products(). Never called directly.

Returns nothing.

=head2 populate_manufacturers_table()

=head2 populate_orders_table()

Calls populate_order_history_table(), and populate_order_items_table().

=head2 populate_order_history_table()

Called by populate_orders_table().

=head2 populate_order_items_table()

Called by populate_orders_table().

=head2 populate_products_table()

=head2 populate_street_addresses_table()

=head2 populate_customers_table()

=head2 populate_table($csv_file_name, $class_name)

Read the CSV file and use the given L<DBIx::Class> class to populate these tables:

=over 4

=item o produce_classes

=item o product_colors

=item o product_sizes

=item o product_statuses

=item o product_styles

=item o product_types

=back

=head2 populate_tax_rates_table()

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
