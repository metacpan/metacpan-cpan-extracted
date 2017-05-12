#!/usr/bin/perl -w

use strict;

use Test::More;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 5);
}

package My::DBI;

use base 'Class::DBI';
use Class::DBI::Untaint;

use File::Temp qw/tempfile/;
my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });

END { unlink $DB if -e $DB }

__PACKAGE__->set_db(Main => @DSN);

package My::Order;

use base 'My::DBI';

__PACKAGE__->table('orders');
__PACKAGE__->columns(All => qw/itemid orders/);
__PACKAGE__->db_Main->do(
	qq{
	CREATE TABLE orders (
		itemid INTEGER,
		orders INTEGER
	)
});
__PACKAGE__->constrain_column(orders => Untaint => 'integer');

package main;

my $order = My::Order->create({ itemid => 10, orders => 103 });
isa_ok $order => "My::Order";

eval { $order->orders("foo") };
like $@, qr/fails 'untaint' constraint/, "Can't set a string";

my $order2 = eval { My::Order->create({ itemid => 13, orders => "ten" }) };
like $@, qr/fails 'untaint' constraint/, "Can't create with a string";

my $order3 = eval { My::Order->create({ itemid => 14, orders => 0 }) };
isa_ok $order3 => "My::Order" or diag $@;
is $order3->orders, 0, "Create an item with no orders";

