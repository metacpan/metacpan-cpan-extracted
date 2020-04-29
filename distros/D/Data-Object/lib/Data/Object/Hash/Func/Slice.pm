package Data::Object::Hash::Func::Slice;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Hash::Func';

our $VERSION = '2.05'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'HashLike',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[StringLike]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  return [@{$data}{@args}];
}

sub mapping {
  return ('arg1', '@args');
}

1;
