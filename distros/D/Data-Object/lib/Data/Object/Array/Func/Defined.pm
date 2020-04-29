package Data::Object::Array::Func::Defined;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Array::Func';

our $VERSION = '2.05'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'ArrayLike',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'NumberLike',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $index) = $self->unpack;

  return 1 unless $index;

  return defined($data->[$index]) ? 1 : 0;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;
