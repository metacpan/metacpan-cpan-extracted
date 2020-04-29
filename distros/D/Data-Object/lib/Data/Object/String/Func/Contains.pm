package Data::Object::String::Func::Contains;

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

has arg2 => (
  is => 'ro',
  isa => 'StringLike | RegexpLike',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $pattern) = $self->unpack;

  return 0 unless defined($pattern);

  my $regexp = UNIVERSAL::isa($pattern, 'Regexp');

  return index("$data", $pattern) < 0 ? 0 : 1 if !$regexp;

  return ("$data" =~ $pattern) ? 1 : 0;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;
