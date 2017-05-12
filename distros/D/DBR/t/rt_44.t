#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More;

my $dbr = setup_schema_ok('rt_44');

my $dbh = $dbr->connect('rt_44');
ok($dbh, 'dbr connect');

my $items = eval{ $dbh->cart->all };
ok( defined($items), 'items = dbh->cart->all ... ' . $@ );

my $total_bucks = 0;
my $total_cents = 0;

my $rv;
while (my $item = $items->next()) {

  ok( defined( $item), 'item = items->next' );

  my $name = eval{ $item->name };
  ok( defined($name), 'name = item->name (' . $name . ') ... ' . $@ );

  my $price = eval{ $item->price };
  ok( defined($price), 'price = item->price (' . $price . ') ... ' . $@ );

  # add bucks

  eval{ $total_bucks += $price };
  ok( !$@ && $total_bucks, 'total_bucks += price  (' . $total_bucks . ') ... ' . $@ );

  my $foo_bucks;  # an undefined value
  eval{ $foo_bucks += $price };
  ok( !$@ &&  defined($foo_bucks), 'foo_bucks += price (' . $foo_bucks . ') ... ' . $@ );

  $rv = eval{ $price eq '' };
  ok( !$@ , "dollar value eq ''" . $@ );

  $rv = eval{ $price ne '' };
  ok( !$@ , "dollar value ne ''" . $@ );


  # add cents

  eval{ no warnings; $total_cents += $price->cents };
  ok( !$@ && $total_cents, 'total_cents += price->cents  (' . $total_cents . ') ... ' . $@ );

  my $foo_cents;  # an undefined value
  eval{ no warnings; $foo_cents += $price->cents };
  ok( !$@ && defined($foo_cents), 'foo_cents += price->cents (' . $foo_cents . ') ... ' . $@ );
}

done_testing();
