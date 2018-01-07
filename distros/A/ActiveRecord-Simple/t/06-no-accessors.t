#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

package Customer;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use parent 'ActiveRecord::Simple';


__PACKAGE__->make_columns_accessors(0);

__PACKAGE__->table_name('customer');
__PACKAGE__->columns(qw/id first_name last_name email/);
__PACKAGE__->primary_key('id');




package main;

use Test::More;

my $customer = Customer->new(
	id => 2,
	first_name => 'Bob',
	last_name => 'Rock!',
	email => 'bob@rock.com',
);

eval { $customer->id(1) };
ok $@;
like $@, qr/Can't locate object method "id"/;

is $customer->{id}, 2;
is $customer->{first_name}, 'Bob';


done_testing();