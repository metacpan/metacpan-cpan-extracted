package Sakila::Country::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Country;

sub object_class { 'Sakila::Country' }

__PACKAGE__->make_manager_methods('country');

1;

