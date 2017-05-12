package Sakila::Inventory::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Inventory;

sub object_class { 'Sakila::Inventory' }

__PACKAGE__->make_manager_methods('inventory');

1;

