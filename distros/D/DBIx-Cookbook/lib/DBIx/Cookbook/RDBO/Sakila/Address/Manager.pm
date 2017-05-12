package Sakila::Address::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Address;

sub object_class { 'Sakila::Address' }

__PACKAGE__->make_manager_methods('address');

1;

