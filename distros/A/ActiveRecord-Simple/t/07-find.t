#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use FindBin '$Bin';
use lib "$Bin/../lib";
use Data::Dumper;
use Test::More;

use DBI;

eval { require DBD::SQLite } or plan skip_all => 'Need DBD::SQLite for testing';


package Customer;

use parent 'ActiveRecord::Simple';


__PACKAGE__->table_name('customers');
__PACKAGE__->primary_key('id');
__PACKAGE__->columns(qw/id first_name second_name age email/);

__PACKAGE__->has_one(info => 'CustomersInfo');


package main;

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","")
	or die DBI->errstr;

my $_INIT_SQL = q{

	CREATE TABLE `customers` (
  		`id` int AUTO_INCREMENT,
  		`first_name` varchar(200) NULL,
  		`second_name` varchar(200) NOT NULL,
  		`age` tinyint(2) NULL,
  		`email` varchar(200) NOT NULL,
  		PRIMARY KEY (`id`)
	);

};

my $_DATA_SQL = q{

	INSERT INTO `customers` (`id`, `first_name`, `second_name`, `age`, `email`)
	VALUES
		(1,'Bob','Dylan',NULL,'bob.dylan@aol.com'),
		(2,'John','Doe',77,'john@doe.com'),
		(3,'Bill','Clinton',50,'mynameisbill@gmail.com'),
		(4,'Bob','Marley',NULL,'bob.marley@forever.com'),
		(5,'','',NULL,'foo.bar@bazz.com');

};

$dbh->do($_INIT_SQL);
$dbh->do($_DATA_SQL);

Customer->dbh($dbh);
my $finder = Customer->find({ first_name => 'Bob' });
isa_ok $finder, 'ActiveRecord::Simple::Find';

#while (my $bob = Customer->find({ first_name => 'Bob' })->next) {
#	say Dumper $bob;
#}
my $f = Customer->find({ first_name => 'Bob' });
while (my $bob = $f->next) {
	say Dumper $bob;
}

ok my $Bob = Customer->find({ first_name => 'Bob' })->fetch, 'find Bob';

isa_ok $Bob, 'Customer';

is $Bob->first_name, 'Bob', 'Bob has a right name';
is $Bob->second_name, 'Dylan';
ok !$Bob->age;

ok my $John = Customer->get(2), 'get John';
is $John->first_name, 'John';

ok my $Bill = Customer->find('second_name = ?', 'Clinton')->fetch, 'find Bill';
is $Bill->first_name, 'Bill';

ok my @customers = Customer->get([1, 2, 3]), 'get customers with #1,2,3';
is scalar @customers, 3;
is $customers[0]->first_name, 'Bob';
is $customers[1]->first_name, 'John';
is $customers[2]->first_name, 'Bill';

eval { Customer->get(1)->fetch };
ok $@, 'fetch after get causes die';

ok my $cnt = Customer->count, 'count';
is $cnt, 5;

ok my $exists = Customer->exists({ first_name => 'Bob' }), 'exists';
is $exists, 1;

ok(!Customer->exists({ first_name => 'Not Found' }));
is(Customer->exists({ first_name => 'Not Found' }), 0);

ok my $first = Customer->first->fetch, 'first';
is_deeply $first, $Bob;

ok my $last = Customer->last->fetch, 'last';
is $last->id, 5;

ok my $customized = Customer->find({ first_name => 'Bob' })->only('id')->fetch, 'only';
is $customized->id, 1;
ok !$customized->first_name;

ok my $customized2 = Customer->find({ first_name => 'Bob' })->fields('id')->fetch, 'fields (alias to "only")';
is $customized2->id, 1;
ok !$customized2->first_name;

my $c = Customer->first->only('first_name');
is scalar @{ $c->{prep_select_fields} }, 2;
is_deeply $c->{prep_select_fields}, ['"customers"."first_name"', '"customers"."id"'];

$c = Customer->first->only('id');
is scalar @{ $c->{prep_select_fields} }, 1;
is_deeply $c->{prep_select_fields}, ['"customers"."id"'];

ok $first = Customer->first->only('id')->fetch, 'first->only';
is $first->id, 1;
ok !$first->first_name;

ok $last = Customer->last->fetch, 'last';
is $last->id, 5;

ok my @list = Customer->find->order_by('id')->desc->fetch, 'order_by, desc';
is $list[4]->id, 1;

undef @list;
ok @list = Customer->find->order_by('id')->asc->fetch, 'order_by, asc';
is $list[4]->id, 5;

ok @list = Customer->find->limit(2)->fetch, 'limit';
is scalar @list, 2;

ok @list = Customer->find->order_by('id')->offset(2)->fetch, 'offset';
is $list[0]->id, 3;

ok @list = Customer->find->abstract({
	order_by => 'id',
	desc => 1,
	offset => 1,
	limit => 2
})->fetch, 'abstract';

is scalar @list, 2;
is $list[0]->id, 4;

undef @list;

ok @list = Customer->select(undef, {
	order_by => 'id',
	desc     => 1,
	offset   => 1,
	limit    => 2
}), 'select';

is scalar @list, 2;
is $list[0]->id, 4;

ok $Bill = Customer->select({ first_name => 'Bill' }, { only => ['id'] });
ok $Bill->id;
ok !$Bill->first_name;

undef @list;

ok @list = Customer->select('id > ?', 2, { order_by => 'id', desc => 1 });
is scalar @list, 3;
is $list[2]->id, 3;

undef @list;
undef $Bill;

ok $Bill = Customer->select({ first_name => 'Bill' });
is $Bill->first_name, 'Bill';

ok @list = Customer->select;
is @list, 5;

undef @list;

ok @list = Customer->select([2, 1, 3], { order_by => 'id' });
is @list, 3;

undef @list;

done_testing();
