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
__PACKAGE__->columns(qw/id first_name second_name age email regdate/);

__PACKAGE__->has_one(info => 'CustomersInfo');


package main;
use Test::More;

eval { require DBD::SQLite } or plan skip_all => 'Need DBD::SQLite for testing';

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","")
	or die DBI->errstr;

my $_INIT_SQL = q{

	CREATE TABLE `customers` (
  		`id` int AUTO_INCREMENT,
  		`first_name` varchar(200) NULL,
  		`second_name` varchar(200) NOT NULL,
  		`age` tinyint(2) NULL,
  		`email` varchar(200) NOT NULL,
  		`regdate` timestamp NOT NULL,
  		PRIMARY KEY (`id`)
	);

};

my $_DATA_SQL = q{

	INSERT INTO `customers` (`id`, `first_name`, `second_name`, `age`, `email`, `regdate`)
	VALUES
		(1,'Bob','Dylan',NULL,'bob.dylan@aol.com', CURRENT_TIMESTAMP),
		(2,'John','Doe',77,'john@doe.com', CURRENT_TIMESTAMP),
		(3,'Bill','Clinton',50,'mynameisbill@gmail.com', CURRENT_TIMESTAMP),
		(4,'Bob','Marley',NULL,'bob.marley@forever.com', CURRENT_TIMESTAMP),
		(5,'','',NULL,'foo.bar@bazz.com', CURRENT_TIMESTAMP);

};

$dbh->do($_INIT_SQL);
$dbh->do($_DATA_SQL);




Customer->dbh($dbh);

ok my $Bill = Customer->get(3), 'get Bill';
is $Bill->first_name, 'Bill', 'first_name is Bill';
ok $Bill->first_name('George'), 'set first_name to George';
is $Bill->first_name, 'George';
ok $Bill->save, 'saving';

ok my $George = Customer->get(3), 'get George';
is $George->first_name, 'George';

ok my $James = Customer->new({
	id => 6,
	first_name => 'James',
	second_name  => 'Hatfield',
	email => 'James.Hatfield@aol.com',
	regdate => \'CURRENT_TIMESTAMP',
}), 'new customer';

ok $James->save, 'saving';

undef $James;
ok !$James;

ok $James = Customer->find({ first_name => 'James' })->fetch;
is $James->first_name, 'James';

ok $James->delete, 'delete James';
ok ! Customer->exists({ first_name => 'James' }), 'totally deleted';




done_testing();