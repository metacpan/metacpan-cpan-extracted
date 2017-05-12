#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use FindBin '$Bin';
use lib "$Bin/../lib";
use Test::More;


BEGIN {

	package Schema;

	use parent 'ActiveRecord::Simple';

	eval { require DBD::SQLite } or exit 0;

	__PACKAGE__->connect("dbi:SQLite:dbname=:memory:","","");



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

	Schema->dbh->do($_INIT_SQL_CUSTOMERS);
	Schema->dbh->do($_DATA_SQL_CUSTOMERS);

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

	Schema->dbh->do($_INIT_SQL_ORDERS);
	Schema->dbh->do($_DATA_SQL_ORDERS);

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

	Schema->dbh->do($_INIT_SQL_ACHIEVEMENTS);
	Schema->dbh->do($_DATA_SQL_ACHEIVEMENTS);

	my $_INIT_SQL_CA = q{

	CREATE TABLE `customers_achievements` (
		`customer_id` int NOT NULL references customers (id),
		`achievement_id` int NOT NULL references achievements (id)
	);

	};

	my $_DATA_SQL_CA = q{

	INSERT INTO `customers_achievements` (`customer_id`, `achievement_id`)
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

__PACKAGE__->load_info();
__PACKAGE__->has_many('orders' => 'Order');
__PACKAGE__->has_many('achievements' => { 'CustomersAchievement' => 'Achievement' });


package Order;

our @ISA = qw/Schema/;

__PACKAGE__->load_info();
__PACKAGE__->belongs_to(customer => 'Customer');


package Achievement;

our @ISA = qw/Schema/;

__PACKAGE__->load_info();
__PACKAGE__->has_many(customers => { 'CustomersAchievement' => 'Customer' });


package CustomersAchievement;

our @ISA = qw/Schema/;

__PACKAGE__->load_info();
__PACKAGE__->belongs_to(customer => 'Customer');
__PACKAGE__->belongs_to(achievement => 'Achievement');


package main;


ok my $Bill = Customer->find({ first_name => 'Bill' })->fetch, 'get Bill';
ok $Bill->orders(Order->new({ title => 'Test smart accessor', amount => '100' }))->save;
ok my $order = Order->find({ title => 'Test smart accessor' })->fetch, 'one->many, yep!';

my $new_order = Order->new({ title => 'New Order vol. 1', amount => '7.77', customer_id => 1 })->save;
ok $new_order->customer($Bill)->save;

is $new_order->customer_id, $Bill->id, 'many->one, good!';

my $new_order2 = Order->new({ title => 'New Order vol. 2', amount => '7.78', customer => $Bill });
$new_order2->save;
ok my $no2 = Order->find({ title => 'New Order vol. 2' })->fetch;
is $no2->customer_id, $Bill->id, 'saving with relational accessors works fine';

ok my @orders = Order->find({ customer => $Bill })->fetch;
is scalar @orders, 3, 'accessors in find';

is(Order->count({ customer => $Bill }), scalar @orders, 'accessors in count');

done_testing();
