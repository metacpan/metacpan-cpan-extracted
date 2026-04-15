#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

{
    package Packing;
    use Role;
    requires qw/pack/;

    package Packing::Bottle;
    use Class;
    with qw/Packing/;
    sub pack { 'Bottle' }

    package Item;
    use Role;
    requires qw/name price packing/;

    package Item::ColdDrink;
    use Role;
    with qw/Item/;
    requires qw/name price/;
    sub packing { Packing::Bottle->new }

    package Item::ColdDrink::Coke;
    use Class;
    with qw/Item::ColdDrink/;
    sub name  { 'Coke' }
    sub price { 12 }
}

my $coke;
eval { $coke = Item::ColdDrink::Coke->new };
ok(!$@, "Coke object can be created without role composition errors")
    or diag $@;

ok($coke->can('packing'), 'Coke object has packing() method');
is($coke->packing->pack, 'Bottle', 'packing() returns Packing::Bottle instance');

done_testing;
