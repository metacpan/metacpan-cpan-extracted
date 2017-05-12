package Sakila::City::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::City;

sub object_class { 'Sakila::City' }

__PACKAGE__->make_manager_methods('city');

1;

