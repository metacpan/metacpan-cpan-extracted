package Sakila::Rental::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Rental;

sub object_class { 'Sakila::Rental' }

__PACKAGE__->make_manager_methods('rental');

1;

