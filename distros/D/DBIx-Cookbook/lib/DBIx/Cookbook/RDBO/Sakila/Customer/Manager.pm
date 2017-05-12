package Sakila::Customer::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Customer;

sub object_class { 'Sakila::Customer' }

__PACKAGE__->make_manager_methods('customer');

1;

