#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Role'); }

# Define a base role with requirements
{
    package Item;
    use Role;
    requires qw/name price/;
}

ok(Role::is_role('Item'), 'Item is recognized as a role');
is_deeply(
    [ sort @{ $Role::REQUIRED_METHODS{'Item'} } ],
    [ qw/name price/ ],
    'Item recorded required methods'
);

# Define a role that consumes another role and adds its own requirement
{
    package Item::ColdDrink;
    use Role;
    with qw/Item/;
    requires qw/temperature/;
}

ok(Role::is_role('Item::ColdDrink'), 'Item::ColdDrink is a role');
ok(
    grep($_ eq 'Item', @{ $Role::APPLIED_ROLES{'Item::ColdDrink'} }),
    'Item::ColdDrink composed Item role'
);

is_deeply(
    [ sort @{ $Role::REQUIRED_METHODS{'Item::ColdDrink'} } ],
    [ qw/name price temperature/ ],
    'Item::ColdDrink inherited Item’s requires and added temperature'
);

# Define a class missing one required method → should die
my $err;
{
    package Drink::Fail;
    use Class;
    sub name  { 'Pepsi' }
    sub price { 1.75 }

    # capture runtime error from role application
    eval { with 'Item::ColdDrink' };
    $err = $@;
}

like(
    $err,
    qr/requires method\(s\).*temperature/,
    'Fails because missing required method temperature'
);

# Define a working class that satisfies all required methods
{
    package Drink::Okay;
    use Class;
    sub name        { 'Fanta' }
    sub price       { 1.80 }
    sub temperature { 'cold' }
    with qw/Item::ColdDrink/;
}

ok(Drink::Okay->can('name'),        'Drink::Okay implements name');
ok(Drink::Okay->can('price'),       'Drink::Okay implements price');
ok(Drink::Okay->can('temperature'), 'Drink::Okay implements temperature');

my @applied = Role::get_applied_roles('Drink::Okay');
ok(grep { $_ eq 'Item::ColdDrink' } @applied, 'Drink::Okay has Item::ColdDrink applied');

done_testing;
