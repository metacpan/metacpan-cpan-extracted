package Sakila::FilmCategory::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::FilmCategory;

sub object_class { 'Sakila::FilmCategory' }

__PACKAGE__->make_manager_methods('film_category');

1;

