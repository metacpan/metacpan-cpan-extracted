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


package main;

use Test::More;

eval { require DBD::SQLite } or plan skip_all => 'Need DBD::SQLite for testing';

ok(Customer->connect("dbi:SQLite:dbname=:memory:","",""), 'connect');
my $hello = Customer->dbh->selectrow_array('SELECT "hello"');
is $hello, 'hello';

done_testing();