BEGIN {

	package Schema;

	use FindBin '$Bin';
	use lib "$Bin/../lib";

	use parent 'ActiveRecord::Simple';

	__PACKAGE__->connect("dbi:SQLite:dbname=:memory:","","");

	my $_DROP_SQL_CUSTOMER = q{
		DROP TABLE IF EXISTS customer;
	};

	my $_INIT_SQL_CUSTOMER = q{
	CREATE TABLE `customer` (
  		`id` int AUTO_INCREMENT,
  		`first_name` varchar(200) NULL,
  		`last_name` varchar(200) NOT NULL,
  		`age` tinyint(2) NULL,
  		`email` varchar(200) NOT NULL,
  		PRIMARY KEY (`id`)
	);
};

	my $_DATA_SQL_CUSTOMER = q{
	INSERT INTO `customer` (`id`, `first_name`, `last_name`, `age`, `email`)
	VALUES
		(1,'Bob','Dylan',NULL,'bob.dylan@aol.com'),
		(2,'John','Doe',77,'john@doe.com'),
		(3,'Bill','Clinton',50,'mynameisbill@gmail.com'),
		(4,'Bob','Marley',NULL,'bob.marley@forever.com'),
		(5,'','',NULL,'foo.bar@bazz.com');
	};

	Schema->dbh->do($_DROP_SQL_CUSTOMER);
	Schema->dbh->do($_INIT_SQL_CUSTOMER);
	Schema->dbh->do($_DATA_SQL_CUSTOMER);

	my $_DROP_SQL_PURCHASE = q{
		DROP TABLE IF EXISTS purchase;
	};

	my $_INIT_SQL_PURCHASE = q{
	CREATE TABLE `purchase` (
		`id` int AUTO_INCREMENT,
		`title` varchar(200) NOT NULL,
		`amount` decimal(10,2) NOT NULL DEFAULT 0.0,
		`customer_id` int NOT NULL references `customer` (`id`),
		PRIMARY KEY (`id`)
	);
	};

	my $_DATA_SQL_PURCHASE = q{
	INSERT INTO `purchase` (`id`, `title`, `amount`, `customer_id`)
	VALUES
		(1, 'The Order #1', 10, 1),
		(2, 'The Order #2', 5.66, 2),
		(3, 'The Order #3', 6.43, 3),
		(4, 'The Order #4', 2.20, 1),
		(5, 'The Order #5', 3.39, 4);
	};

	Schema->dbh->do($_DROP_SQL_PURCHASE);
	Schema->dbh->do($_INIT_SQL_PURCHASE);
	Schema->dbh->do($_DATA_SQL_PURCHASE);

	my $_DROP_SQL_ACHIEVEMENT = q{
		DROP TABLE IF EXISTS achievement;
	};

	my $_INIT_SQL_ACHIEVEMENT = q{
	CREATE TABLE `achievement` (
		`id` int AUTO_INCREMENT,
		`title` varchar(30) NOT NULL,
		PRIMARY KEY (`id`)
	);
	};

	my $_DATA_SQL_ACHEIVEMENT = q{
	INSERT INTO `achievement` (`id`, `title`)
	VALUES
		(1, 'Bronze'),
		(2, 'Silver'),
		(3, 'Gold');
	};

	Schema->dbh->do($_DROP_SQL_ACHIEVEMENT);
	Schema->dbh->do($_INIT_SQL_ACHIEVEMENT);
	Schema->dbh->do($_DATA_SQL_ACHEIVEMENT);

	my $_DROP_SQL_CA = q{
		DROP TABLE IF EXISTS customer_achievement;
	};

	my $_INIT_SQL_CA = q{
	CREATE TABLE `customer_achievement` (
		`customer_id` int NOT NULL references customer (id),
		`achievement_id` int NOT NULL references achievement (id)
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

	Schema->dbh->do($_DROP_SQL_CA);
	Schema->dbh->do($_INIT_SQL_CA);
	Schema->dbh->do($_DATA_SQL_CA);
}




package Purchase;

our @ISA = qw/Schema/;

__PACKAGE__->table_name('purchase');
__PACKAGE__->columns(qw/id title amount customer_id/);
__PACKAGE__->primary_key('id');

__PACKAGE__->belongs_to(customer => 'Customer');


package Customer;

our @ISA = qw/Schema/;

__PACKAGE__->table_name('customer');
__PACKAGE__->columns(qw/id first_name last_name age email/);
__PACKAGE__->primary_key('id');

__PACKAGE__->has_many(purchases => 'Purchase');
__PACKAGE__->has_many(achievements => 'Achievement', { via => 'customer_achievement' });


package Achievement;

our @ISA = qw/Schema/;

__PACKAGE__->table_name('achievement');
__PACKAGE__->columns(qw/id title/);
__PACKAGE__->primary_key('id');

__PACKAGE__->has_many(customers => 'Customer', { via => 'customer_achievement' });




package main;

use Test::More;
use Data::Dumper;
use 5.010;


ok my $customer = Customer->get(1);
is $customer->first_name, 'Bob';

my @purchases = $customer->purchases->fetch;
is scalar @purchases, 2;

my $purchase = Purchase->get(2);
is $purchase->id, 2;
is $purchase->title, 'The Order #2';
is $purchase->customer->first_name, 'John';

my $achievement = Achievement->get(1);
is $achievement->title, 'Bronze';

my @customers = $achievement->customers->fetch;
is scalar @customers, 3;

my @achievements = $customer->achievements->fetch;
is scalar @achievements, 2;


ok my $Bill = Customer->get(3), 'got Bill';
ok $achievement = Achievement->new({ title => 'Bill Achievement', id => 4 })->save, 'create achievement';

is $Bill->id, 3;
is $achievement->id, 4;

ok $Bill->achievements($achievement)->save, 'trying to bind achievement to the customer';

ok my $cnt = $Bill->achievements({ title => 'Bill Achievement' })->count(), 'trying to count customers achievements';
is $cnt, 1, 'looks good';

ok $Bill->achievements({ title => 'Bill Achievement' })->exists;
ok !$Bill->achievements({ title => 'Not Existing Achievement' })->exists;

ok my @bills_orders = $Bill->purchases->fetch, 'got Bill\'s orders';

is scalar @bills_orders, 1;
ok my $order = Purchase->get(3), 'order';
ok $order->customer, 'the order has a customer';
is $order->customer->id, $bills_orders[0]->id;

ok @achievements = $Bill->achievements->fetch;#

is @achievements, 4;
isa_ok $achievements[0], 'Achievement';

ok my $a = Achievement->get(1);
ok @customers = $a->customers->order_by('id')->fetch;
is @customers, 3;



done_testing();