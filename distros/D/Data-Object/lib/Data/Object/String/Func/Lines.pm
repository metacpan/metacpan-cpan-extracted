package Data::Object::String::Func::Lines;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::String::Func';

our $VERSION = '2.05'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'StringLike',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data) = $self->unpack;

  return [split(/[\n\r]+/, "$data")];
}

sub mapping {
  return ('arg1');
}

1;
