#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use FindBin '$Bin';
use lib "$Bin/../lib";
use Data::Dumper;

use DBI;


package Customer;

use parent 'ActiveRecord::Simple';


__PACKAGE__->table_name('customers');
__PACKAGE__->primary_key('id');
__PACKAGE__->columns(qw/id first_name second_name age email/);

__PACKAGE__->has_many('orders' => 'Order');
__PACKAGE__->has_many('achievements' => { CustomersAchievement => 'Achievement' });


package Order;

use parent 'ActiveRecord::Simple';


__PACKAGE__->table_name('orders');
__PACKAGE__->primary_key('id');
__PACKAGE__->columns(qw/id title amount customer_id/);

__PACKAGE__->belongs_to(customer => 'Customer');


package Achievement;

use parent 'ActiveRecord::Simple';


__PACKAGE__->table_name('achievements');
__PACKAGE__->primary_key('id');
__PACKAGE__->columns(qw/id title/);

__PACKAGE__->has_many(customers => { 'CustomersAchievement' => 'Customer' });


package CustomersAchievement;

use parent 'ActiveRecord::Simple';


__PACKAGE__->table_name('customers_achievents');
__PACKAGE__->columns(qw/customer_id acheivement_id/);

__PACKAGE__->belongs_to(customer => 'Customer');
__PACKAGE__->belongs_to(achievement => 'Achievement');


package main;

use Test::More;

eval { require DBD::SQLite } or plan skip_all => 'Need DBD::SQLite for testing';

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","")
	or die DBI->errstr;

my $_INIT_SQL_CUSTOMERS = q{

	CREATE TABLE `customers` (
  		`id` int AUTO_INCREMENT,
  		`first_name` varchar(200) NULL,
  		`second_name` varchar(200) NOT NULL,
  		`age` tinyint(2) NULL,
  		`email` varchar(200) NOT NULL,
  		PRIMARY KEY (`id`)
	);

};

my $_DATA_SQL_CUSTOMERS = q{

	INSERT INTO `customers` (`id`, `first_name`, `second_name`, `age`, `email`)
	VALUES
		(1,'Bob','Dylan',NULL,'bob.dylan@aol.com'),
		(2,'John','Doe',77,'john@doe.com'),
		(3,'Bill','Clinton',50,'mynameisbill@gmail.com'),
		(4,'Bob','Marley',NULL,'bob.marley@forever.com'),
		(5,'','',NULL,'foo.bar@bazz.com');

};

$dbh->do($_INIT_SQL_CUSTOMERS);
$dbh->do($_DATA_SQL_CUSTOMERS);

my $_INIT_SQL_ORDERS = q{

	CREATE TABLE `orders` (
		`id` int AUTO_INCREMENT,
		`title` varchar(200) NOT NULL,
		`amount` decimal(10,2) NOT NULL DEFAULT 0.0,
		`customer_id` int NOT NULL references `customers` (`id`),
		PRIMARY KEY (`id`)
	);

};

my $_DATA_SQL_ORDERS = q{

	INSERT INTO `orders` (`id`, `title`, `amount`, `customer_id`)
	VALUES
		(1, 'The Order #1', 10, 1),
		(2, 'The Order #2', 5.66, 2),
		(3, 'The Order #3', 6.43, 3),
		(4, 'The Order #4', 2.20, 1),
		(5, 'The Order #5', 3.39, 4);

};

$dbh->do($_INIT_SQL_ORDERS);
$dbh->do($_DATA_SQL_ORDERS);

my $_INIT_SQL_ACHIEVEMENTS = q{

	CREATE TABLE `achievements` (
		`id` int AUTO_INCREMENT,
		`title` varchar(30) NOT NULL,
		PRIMARY KEY (`id`)
	);

};

my $_DATA_SQL_ACHEIVEMENTS = q{

	INSERT INTO `achievements` (`id`, `title`)
	VALUES
		(1, 'Bronze'),
		(2, 'Silver'),
		(3, 'Gold');

};

$dbh->do($_INIT_SQL_ACHIEVEMENTS);
$dbh->do($_DATA_SQL_ACHEIVEMENTS);

my $_INIT_SQL_CA = q{

	CREATE TABLE `customers_achievents` (
		`customer_id` int NOT NULL references customers (id),
		`achievement_id` int NOT NULL references achievements (id)
	);

};

my $_DATA_SQL_CA = q{

	INSERT INTO `customers_achievents` (`customer_id`, `achievement_id`)
	VALUES
		(1, 1),
		(1, 2),
		(2, 1),
		(2, 3),
		(3, 1),
		(3, 2),
		(3, 3);

};

$dbh->do($_INIT_SQL_CA);
$dbh->do($_DATA_SQL_CA);


Customer->dbh($dbh);

ok my $Bill = Customer->get(3), 'got Bill';
ok my @bills_orders = $Bill->orders->fetch, 'got Bill\'s orders';

is scalar @bills_orders, 1;
ok my $order = Order->get(3), 'order';
ok $order->customer, 'the order has a customer';
is $order->customer->id, $bills_orders[0]->id;

pass 'PASS one to many / many to one';

ok my @achievements = $Bill->achievements->fetch;

is @achievements, 3;
isa_ok $achievements[0], 'Achievement';

ok my $a = Achievement->get(1);
ok my @customers = $a->customers->order_by('id')->fetch;
is @customers, 3;

pass 'PASS many to many';


done_testing();