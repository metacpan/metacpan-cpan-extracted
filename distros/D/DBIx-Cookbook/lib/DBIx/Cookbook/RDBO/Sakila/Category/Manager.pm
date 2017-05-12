package Sakila::Category::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Category;

sub object_class { 'Sakila::Category' }

__PACKAGE__->make_manager_methods('category');

1;

