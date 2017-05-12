package Sakila::Film::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Film;

sub object_class { 'Sakila::Film' }

__PACKAGE__->make_manager_methods('film');

1;

