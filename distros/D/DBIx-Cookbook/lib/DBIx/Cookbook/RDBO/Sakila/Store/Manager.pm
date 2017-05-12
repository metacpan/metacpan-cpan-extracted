package Sakila::Store::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Store;

sub object_class { 'Sakila::Store' }

__PACKAGE__->make_manager_methods('store');

1;

