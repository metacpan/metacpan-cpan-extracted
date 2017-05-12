package Sakila::FilmActor::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::FilmActor;

sub object_class { 'Sakila::FilmActor' }

__PACKAGE__->make_manager_methods('film_actor');

1;

