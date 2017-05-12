package Sakila::Staff::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Staff;

sub object_class { 'Sakila::Staff' }

__PACKAGE__->make_manager_methods('staff');

1;

