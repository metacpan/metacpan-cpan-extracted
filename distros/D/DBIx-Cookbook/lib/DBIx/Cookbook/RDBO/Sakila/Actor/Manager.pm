package Sakila::Actor::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Actor;

sub object_class { 'Sakila::Actor' }

__PACKAGE__->make_manager_methods('actor');

1;

