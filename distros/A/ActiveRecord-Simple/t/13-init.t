#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Test::More;

use FindBin '$Bin';
use lib "$Bin/../lib";


BEGIN {

	package Schema;

	use parent 'ActiveRecord::Simple';

	eval { require DBD::SQLite } or exit 0;

	__PACKAGE__->connect("dbi:SQLite:dbname=:memory:","","");



	my $_INIT_SQL_CUSTOMERS = q{
	CREATE TABLE `customer` (
  		`id` int AUTO_INCREMENT,
  		`first_name` varchar(200) NULL,
  		`second_name` varchar(200) NOT NULL,
  		`age` tinyint(2) NULL,
  		`email` varchar(200) NOT NULL,
  		PRIMARY KEY (`id`)
	);
};

	my $_DATA_SQL_CUSTOMERS = q{
	INSERT INTO `customer` (`id`, `first_name`, `second_name`, `age`, `email`)
	VALUES
		(1,'Bob','Dylan',NULL,'bob.dylan@aol.com'),
		(2,'John','Doe',77,'john@doe.com'),
		(3,'Bill','Clinton',50,'mynameisbill@gmail.com'),
		(4,'Bob','Marley',NULL,'bob.marley@forever.com'),
		(5,'','',NULL,'foo.bar@bazz.com');
	};

	Schema->dbh->do($_INIT_SQL_CUSTOMERS);
	Schema->dbh->do($_DATA_SQL_CUSTOMERS);

	my $_INIT_SQL_ORDERS = q{
	CREATE TABLE `order` (
		`id` int AUTO_INCREMENT,
		`title` varchar(200) NOT NULL,
		`amount` decimal(10,2) NOT NULL DEFAULT 0.0,
		`customer_id` int NOT NULL references `customers` (`id`),
		PRIMARY KEY (`id`)
	);
	};

	my $_DATA_SQL_ORDERS = q{
	INSERT INTO `order` (`id`, `title`, `amount`, `customer_id`)
	VALUES
		(1, 'The Order #1', 10, 1),
		(2, 'The Order #2', 5.66, 2),
		(3, 'The Order #3', 6.43, 3),
		(4, 'The Order #4', 2.20, 1),
		(5, 'The Order #5', 3.39, 4);
	};

	Schema->dbh->do($_INIT_SQL_ORDERS);
	Schema->dbh->do($_DATA_SQL_ORDERS);

	my $_INIT_SQL_ACHIEVEMENTS = q{
	CREATE TABLE `achievement` (
		`id` int AUTO_INCREMENT,
		`title` varchar(30) NOT NULL,
		PRIMARY KEY (`id`)
	);
	};

	my $_DATA_SQL_ACHEIVEMENTS = q{
	INSERT INTO `achievement` (`id`, `title`)
	VALUES
		(1, 'Bronze'),
		(2, 'Silver'),
		(3, 'Gold');
	};

	Schema->dbh->do($_INIT_SQL_ACHIEVEMENTS);
	Schema->dbh->do($_DATA_SQL_ACHEIVEMENTS);

	my $_INIT_SQL_CA = q{
	CREATE TABLE `customer_achievement` (
		`customer_id` int NOT NULL references customers (id),
		`achievement_id` int NOT NULL references achievements (id)
	);
	};

	my $_DATA_SQL_CA = q{
	INSERT INTO `customer_achievement` (`customer_id`, `achievement_id`)
	VALUES
		(1, 1),
		(1, 2),
		(2, 1),
		(2, 3),
		(3, 1),
		(3, 2),
		(3, 3);
	};

	Schema->dbh->do($_INIT_SQL_CA);
	Schema->dbh->do($_DATA_SQL_CA);

}


package Customer;

#use parent 'Schema';
our @ISA = qw/Schema/;

__PACKAGE__->auto_load();
__PACKAGE__->has_many(orders => 'Order');
__PACKAGE__->has_many(achievements => 'Achievement', { via => 'customer_achievement' });




package Order;

our @ISA = qw/Schema/;

__PACKAGE__->auto_load();
__PACKAGE__->belongs_to(customer => 'Customer');


package Achievement;

our @ISA = qw/Schema/;

__PACKAGE__->auto_load();
__PACKAGE__->has_many(customers => 'Customer', { via => 'customer_achievement' });


package main;

ok my $Bill = Customer->objects->get(3), 'got Bill';
ok my @bills_orders = $Bill->orders->fetch, 'got Bill\'s orders';

is scalar @bills_orders, 1;
ok my $order = Order->objects->get(3), 'order';
ok $order->customer, 'the order has a customer';
is $order->customer->id, $bills_orders[0]->id, 'id == id';

ok my @achievements = $Bill->achievements->fetch;

is @achievements, 3;
isa_ok $achievements[0], 'Achievement';

ok my $a = Achievement->objects->get(1);
ok my @customers = $a->customers->fetch;
is @customers, 3;

done_testing();