#!/usr/bin/perl


BEGIN {

	package Schema;

	use FindBin qw/$Bin/;
	use lib "$Bin/../lib";

	use parent 'ActiveRecord::Simple';

	eval { require DBD::SQLite } or exit 0;

	__PACKAGE__->connect("dbi:SQLite:dbname=:memory:","","");


	my $_INIT_SQL_CUSTOMER = q{
	
		CREATE TABLE `customer` (
  			`id` int AUTO_INCREMENT,
  			`first_name` varchar(200) NULL,
  			`second_name` varchar(200) NOT NULL,
  			`age` tinyint(2) NULL,
  			`email` varchar(200) NOT NULL,
  			PRIMARY KEY (`id`)
		);

	};

	__PACKAGE__->dbh->do($_INIT_SQL_CUSTOMER);
}

package Customer;
#
our @ISA = qw/Schema/;
#
__PACKAGE__->auto_load();
#
#
package main;

use Test::More;


ok my $customer = Customer->new();
eval { $customer->first_name };
ok ! $@, 'loaded accessor `first_name`';
eval { $customer->id };
ok ! $@, 'loaded accessor `id`';
eval { $customer->foo };
ok $@, 'error load undefined accessor';

is(Customer->_get_table_name, 'customer', 'loaded table name');
is(Customer->_get_primary_key, 'id', 'loaded primary key');


done_testing();


