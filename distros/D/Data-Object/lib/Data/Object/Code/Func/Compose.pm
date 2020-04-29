package Data::Object::Code::Func::Compose;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Code::Func';

our $VERSION = '2.05'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'CodeLike',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'CodeLike',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Any]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $code, @args) = $self->unpack;

  return sub { (sub { $code->($data->(@_)) })->(@args, @_) };
}

sub mapping {
  return ('arg1', 'arg2', '@args');
}

1;
