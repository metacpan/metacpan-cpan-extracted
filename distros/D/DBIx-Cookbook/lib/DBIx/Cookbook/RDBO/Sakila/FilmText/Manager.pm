package Sakila::FilmText::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::FilmText;

sub object_class { 'Sakila::FilmText' }

__PACKAGE__->make_manager_methods('film_text');

1;

