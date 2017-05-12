package Sakila::Payment::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Sakila::Payment;

sub object_class { 'Sakila::Payment' }

__PACKAGE__->make_manager_methods('payment');

1;

