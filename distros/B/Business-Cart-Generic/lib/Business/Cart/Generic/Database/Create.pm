package Business::Cart::Generic::Database::Create;

use strict;
use warnings;

use DBIx::Admin::CreateTable;

use Moose;

use Try::Tiny;

extends 'Business::Cart::Generic::Base';

has creator =>
(
 is       => 'rw',
 isa      => 'DBIx::Admin::CreateTable',
 required => 0,
);

has engine =>
(
 is       => 'rw',
 isa      => 'Str',
 required => 0,
);

has time_option =>
(
 is       => 'rw',
 isa      => 'Str',
 required => 0,
);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> creator
		(
		 DBIx::Admin::CreateTable -> new
		 (
		  dbh     => $self -> connector -> dbh,
		  verbose => 0,
		 )
		);

	$self -> engine
		(
		 $self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : ''
		);

	$self -> time_option
		(
		 $self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : ''
		);

}	# End of BUILD.

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	$self -> connector -> txn
		(
		 fixup => sub{ $self -> create_tables }, catch{ defined $_ ? die $_ : ''}
		);

}	# End of create_all_tables.

# -----------------------------------------------

sub create_tables
{
	my($self) = @_;

	# Warning: The order is important.

	my($method);
	my($table_name);

	# Note: The logger creates the log table, if necessary.

	for $table_name (qw/
log
sessions
yes_no
countries
zones
street_addresses
currencies
languages
manufacturers
manufacturers_info
tax_classes
tax_rates
weight_classes
weight_class_rules
categories
category_descriptions
product_classes
product_colors
product_sizes
product_statuses
product_styles
product_types
products
product_descriptions
products_to_categories
genders
titles
customer_statuses
customer_types
customers
email_address_types
email_addresses
email_lists
phone_number_types
phone_numbers
phone_lists
logons
payment_methods
order_statuses
orders
order_items
order_history
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

}	# End of create_tables.

# --------------------------------------------------

sub create_category_descriptions_table
{
	my($self)        = @_;
	my($table_name)  = 'category_descriptions';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
category_id integer not null references categories(id),
language_id integer not null references languages(id),
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_category_descriptions_table.

# --------------------------------------------------

sub create_categories_table
{
	my($self)        = @_;
	my($table_name)  = 'categories';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
parent_id integer not null,
date_added timestamp $time_option not null,
date_modified timestamp $time_option not null,
image varchar(255) not null,
name varchar(255) not null,
sort_order integer not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_categories_table.

# --------------------------------------------------

sub create_countries_table
{
	my($self)        = @_;
	my($table_name)  = 'countries';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
code varchar(255) not null,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL

	$self -> report($table_name, 'created', $result);

} # End of create_countries_table.

# --------------------------------------------------

sub create_customer_statuses_table
{
	my($self)        = @_;
	my($table_name)  = 'customer_statuses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_customer_statuses_table.

# --------------------------------------------------

sub create_customer_types_table
{
	my($self)        = @_;
	my($table_name)  = 'customer_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_customer_types_table.

# --------------------------------------------------

sub create_customers_table
{
	my($self)        = @_;
	my($table_name)  = 'customers';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
customer_status_id integer not null references customer_statuses(id),
customer_type_id integer not null references customer_types(id),
default_street_address_id integer not null references street_addresses(id),
gender_id integer not null references genders(id),
title_id integer not null references titles(id),
date_added timestamp $time_option not null,
date_of_birth timestamp $time_option not null default '1900-01-01 00:00:00',
date_modified timestamp $time_option not null,
given_names varchar(255) not null,
name varchar(255) not null,
password varchar(255) not null,
preferred_name varchar(255) not null,
surname varchar(255) not null,
upper_name varchar(255) not null,
username varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_customers_table.

# --------------------------------------------------

sub create_currencies_table
{
	my($self)        = @_;
	my($table_name)  = 'currencies';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
code varchar(255) not null,
decimal_places char(1) not null,
name varchar(255) not null,
symbol_left varchar(255) not null,
symbol_right varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_currencies_table.

# --------------------------------------------------

sub create_email_address_types_table
{
	my($self)        = @_;
	my($table_name)  = 'email_address_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_email_address_types_table.

# --------------------------------------------------

sub create_email_addresses_table
{
	my($self)        = @_;
	my($table_name)  = 'email_addresses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
email_address_type_id integer not null references email_address_types(id),
address varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_email_addresses_table.

# --------------------------------------------------

sub create_email_lists_table
{
	my($self)        = @_;
	my($table_name)  = 'email_lists';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
customer_id integer not null references customers,
email_address_id integer not null references email_addresses(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_email_lists_table.

# --------------------------------------------------

sub create_genders_table
{
	my($self)        = @_;
	my($table_name)  = 'genders';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_genders_table.

# --------------------------------------------------

sub create_languages_table
{
	my($self)        = @_;
	my($table_name)  = 'languages';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
currency_id integer not null references currencies(id),
charset varchar(255) not null,
code char(5) not null,
date_format_long varchar(255) not null,
date_format_short varchar(255) not null,
locale varchar(255) not null,
name varchar(255) not null,
numeric_separator_decimal varchar(255) NOT NULL,
numeric_separator_thousands varchar(255) NOT NULL,
text_direction varchar(255) not null,
time_format varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_languages_table.

# --------------------------------------------------

sub create_log_table
{
	my($self)        = @_;
	my($table_name)  = 'log';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($type)        = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
level varchar(255) not null,
message $type not null,
timestamp timestamp $time_option not null default current_timestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_log_table.

# --------------------------------------------------

sub create_logons_table
{
	my($self)        = @_;
	my($table_name)  = 'logons';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
customer_id integer not null references customers(id),
date timestamp $time_option not null default current_timestamp,
ip_address varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_logons_table.

# --------------------------------------------------

sub create_manufacturers_table
{
	my($self)        = @_;
	my($table_name)  = 'manufacturers';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
date_added timestamp $time_option not null,
date_modified timestamp $time_option not null,
image varchar(255) not null,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_manufacturers_table.

# --------------------------------------------------

sub create_manufacturers_info_table
{
	my($self)        = @_;
	my($table_name)  = 'manufacturers_info';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
language_id integer not null references languages(id),
manufacturer_id integer not null references manufacturers(id),
date_last_click timestamp $time_option not null default '1900-01-01 00:00:00',
url varchar(255) not null,
url_clicked integer not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_manufacturers_info_table.

# --------------------------------------------------

sub create_order_history_table
{
	my($self)        = @_;
	my($table_name)  = 'order_history';
	my($type)        = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
order_id integer not null references orders(id),
order_status_id integer not null references order_statuses(id),
customer_notified_id integer not null references yes_no(id),
comment $type,
date_added timestamp $time_option not null,
date_modified timestamp $time_option not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_order_history_table.

# --------------------------------------------------

sub create_order_items_table
{
	my($self)        = @_;
	my($table_name)  = 'order_items';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
order_id integer not null references orders(id),
product_id integer not null references products(id),
model varchar(255) not null,
name varchar(255) not null,
price decimal(15,4) not null,
quantity integer not null,
tax_rate decimal(7,4),
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_order_items_table.

# --------------------------------------------------

sub create_order_statuses_table
{
	my($self)        = @_;
	my($table_name)  = 'order_statuses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
language_id integer not null references languages(id),
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_order_statuses_table.

# --------------------------------------------------

sub create_orders_table
{
	my($self)        = @_;
	my($table_name)  = 'orders';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
billing_address_id integer not null references street_addresses(id),
customer_address_id integer not null references street_addresses(id),
customer_id integer not null references customers(id),
delivery_address_id integer not null references street_addresses(id),
date_added timestamp $time_option not null,
date_completed timestamp $time_option not null default '1900-01-01 00:00:00',
date_modified timestamp $time_option not null,
order_status_id integer not null references order_statuses(id),
payment_method_id integer not null references payment_methods(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_orders_table.

# --------------------------------------------------

sub create_payment_methods_table
{
	my($self)        = @_;
	my($table_name)  = 'payment_methods';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_payment_methods_table.

# --------------------------------------------------

sub create_phone_lists_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_lists';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
customer_id integer not null references customers,
phone_number_id integer not null references phone_numbers(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_phone_lists_table.

# --------------------------------------------------

sub create_phone_number_types_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_number_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_phone_number_types_table.

# --------------------------------------------------

sub create_phone_numbers_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_numbers';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
phone_number_type_id integer not null references phone_number_types(id),
number varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_phone_numbers_table.

# --------------------------------------------------

sub create_product_classes_table
{
	my($self)        = @_;
	my($table_name)  = 'product_classes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_product_classes_table.

# --------------------------------------------------

sub create_product_colors_table
{
	my($self)        = @_;
	my($table_name)  = 'product_colors';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_product_colors_table.

# --------------------------------------------------

sub create_product_descriptions_table
{
	my($self)        = @_;
	my($table_name)  = 'product_descriptions';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
language_id integer not null references languages(id),
description varchar(255) not null,
keyword varchar(255) not null,
name varchar(255) not null,
tags varchar(255) not null,
upper_name varchar(255) not null,
url varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_product_descriptions_table.

# --------------------------------------------------

sub create_product_sizes_table
{
	my($self)        = @_;
	my($table_name)  = 'product_sizes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_product_sizes_table.

# --------------------------------------------------

sub create_product_statuses_table
{
	my($self)        = @_;
	my($table_name)  = 'product_statuses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_product_statuses_table.

# --------------------------------------------------

sub create_product_styles_table
{
	my($self)        = @_;
	my($table_name)  = 'product_styles';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_product_styles_table.

# --------------------------------------------------

sub create_product_types_table
{
	my($self)        = @_;
	my($table_name)  = 'product_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_product_types_table.

# --------------------------------------------------

sub create_products_table
{
	my($self)        = @_;
	my($table_name)  = 'products';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
currency_id integer not null references currencies(id),
manufacturer_id integer not null references manufacturers(id),
parent_id integer not null,
product_status_id integer not null references product_statuses(id),
tax_class_id integer not null references tax_classes(id),
weight_class_id integer not null references weight_classes(id),
date_added timestamp $time_option not null,
date_modified timestamp $time_option not null,
description varchar(255) not null,
has_children varchar(255) not null,
model varchar(255) not null,
name varchar(255) not null,
price decimal(15,4) not null,
quantity_on_hand integer not null,
quantity_ordered integer not null,
upper_name varchar(255) not null,
weight decimal(5,2) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_products_table.

# --------------------------------------------------

sub create_products_to_categories_table
{
	my($self)        = @_;
	my($table_name)  = 'products_to_categories';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
category_id integer not null references categories(id),
product_id integer not null references products(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_products_to_categories_table.

# -----------------------------------------------

sub create_sessions_table
{
	my($self)       = @_;
	my($table_name) = 'sessions';
	my($type)       = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($engine)     = $self -> engine;
	my($result)     = $self -> creator -> create_table(<<SQL, {no_sequence => 1});
create table $table_name
(
id char(32) not null primary key,
a_session $type not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_sessions_table.

# --------------------------------------------------

sub create_street_addresses_table
{
	my($self)        = @_;
	my($table_name)  = 'street_addresses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
country_id integer not null references countries(id),
zone_id integer not null references zones(id),
locality varchar(255) not null,
name varchar(255) not null,
postcode varchar(255) not null,
street_1 varchar(255) not null,
street_2 varchar(255) not null,
street_3 varchar(255) not null,
street_4 varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_street_addresses_table.

# --------------------------------------------------

sub create_tax_classes_table
{
	my($self)        = @_;
	my($table_name)  = 'tax_classes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
date_added timestamp $time_option not null,
date_modified timestamp $time_option not null,
description varchar(255) not null,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_tax_classes_table.

# --------------------------------------------------

sub create_tax_rates_table
{
	my($self)        = @_;
	my($table_name)  = 'tax_rates';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
tax_class_id integer not null references tax_classes(id),
zone_id integer not null references zones(id),
date_added timestamp $time_option not null,
date_modified timestamp $time_option not null,
description varchar(255) not null,
priority integer default 1,
rate decimal(7,4) not null,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_tax_rates_table.

# --------------------------------------------------

sub create_titles_table
{
	my($self)        = @_;
	my($table_name)  = 'titles';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_titles_table.

# --------------------------------------------------

sub create_weight_class_rules_table
{
	my($self)        = @_;
	my($table_name)  = 'weight_class_rules';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
from_id integer not null references weight_classes(id),
to_id integer not null references weight_classes(id),
rule decimal(15,4) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_weight_class_rules_table.

# --------------------------------------------------

sub create_weight_classes_table
{
	my($self)        = @_;
	my($table_name)  = 'weight_classes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
language_id integer not null references languages(id),
key varchar(255) not null,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_weight_classes_table.

# --------------------------------------------------

sub create_yes_no_table
{
	my($self)        = @_;
	my($table_name)  = 'yes_no';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_yes_no_table.

# --------------------------------------------------

sub create_zones_table
{
	my($self)        = @_;
	my($table_name)  = 'zones';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
country_id integer not null references countries(id),
code varchar(255) not null,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

} # End of create_zones_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	$self -> connector -> txn
		(
		 fixup => sub{ $self -> drop_tables }, catch{ defined $_ ? die $_ : ''}
		);

}	# End of drop_all_tables.

# -----------------------------------------------

sub drop_tables
{
	my($self) = @_;

	my($table_name);

	for $table_name (qw/
order_history
order_items
orders
order_statuses
payment_methods
logons
phone_lists
phone_numbers
phone_number_types
email_lists
email_addresses
email_address_types
customers
customer_statuses
customer_types
genders
titles
products_to_categories
product_descriptions
products
product_types
product_styles
product_statuses
product_sizes
product_colors
product_classes
category_descriptions
categories
weight_class_rules
weight_classes
tax_rates
tax_classes
manufacturers_info
manufacturers
languages
currencies
street_addresses
zones
countries
yes_no
sessions
log
/)
	{
		$self -> drop_table($table_name);
	}

}	# End of drop_tables.

# -----------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	$self -> creator -> drop_table($table_name);

	if ($table_name ne 'log')
	{
		$self -> report($table_name, 'dropped');
	}

} # End of drop_table.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		die "Table '$table_name' $result. \n";
	}
	else
	{
		$self -> logger -> log(debug => "Table '$table_name' $message");
	}

} # End of report.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Database::Create> - Basic shopping cart

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

See scripts/create.tables.pl and scripts/drop.tables.pl.

=head1 Methods

=head2 create_all_tables()

Runs a db transaction to create all tables.

Calls create_tables().

Returns nothing.

=head2 create_tables()

Helper for create_all_tables(). Never called directly.

Returns nothing.

=head2 create_categories_table()

=head2 create_category_descriptions_table()

=head2 create_countries_table()

=head2 create_currencies_table()

=head2 create_customers_table()

=head2 create_customer_statuses_table()

=head2 create_customer_types_table()

=head2 create_email_addresses_table()

=head2 create_email_address_types_table()

=head2 create_email_lists_table()

=head2 create_genders_table()

=head2 create_languages_table()

=head2 create_log_table()

=head2 create_logons_table()

=head2 create_manufacturers_table()

=head2 create_manufacturers_info_table()

=head2 create_order_history_table()

=head2 create_order_items_table()

=head2 create_orders_table()

=head2 create_order_statuses_table()

=head2 create_payment_methods_table()

=head2 create_phone_lists_table()

=head2 create_phone_numbers_table()

=head2 create_phone_number_types_table()

=head2 create_product_classes_table()

=head2 create_product_colors_table()

=head2 create_product_descriptions_table()

=head2 create_products_table()

=head2 create_product_sizes_table()

=head2 create_product_statuses_table()

=head2 create_products_to_categories_table()

=head2 create_product_styles_table()

=head2 create_product_types_table()

=head2 create_sessions_table()

=head2 create_street_addresses_table()

=head2 create_tax_classes_table()

=head2 create_tax_rates_table()

=head2 create_titles_table()

=head2 create_weight_classes_table()

=head2 create_weight_class_rules_table()

=head2 create_yes_no_table()

=head2 create_zones_table()

=head2 drop_all_tables()

Runs a db transaction to drop all tables.

Calls drop_tables().

Returns nothing.

=head2 drop_tables()

Helper for drop_all_tables(). Never called directly.

Calls drop_table().

Returns nothing.

=head2 drop_table($table_name)

Drop the named table.

Returns nothing.

=head2 report($table_name, $message, $result)

Report on the success of otherwise of create_table().

Returns nothing.

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
