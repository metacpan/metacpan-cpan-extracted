package My::Object::Customer;
use Moose;
extends 'My::Object::Person';
use namespace::autoclean;

__PACKAGE__->meta->make_immutable;


1;
