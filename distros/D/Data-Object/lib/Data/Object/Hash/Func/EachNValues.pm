package Data::Object::Hash::Func::EachNValues;

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

has arg2 => (
  is => 'ro',
  isa => 'NumberLike',
  req => 1
);

has arg3 => (
  is => 'ro',
  isa => 'CodeLike',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Any]',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my $results = [];

  my ($data, $number, $code, @args) = $self->unpack;

  my $refs = {};
  my @list = keys %$data;

  while (my @keys = splice(@list, 0, $number)) {
    my @values;

    for (my $i = 0; $i < @keys; $i++) {
      my $pos   = $i;
      my $key   = $keys[$pos];
      my $value = defined($key) ? $data->{$key} : undef;

      push @values, $value;
    }

    push @$results, $code->(@values, @args);
  }

  return $results;
}

sub mapping {
  return ('arg1', 'arg2', 'arg3', '@args');
}

1;
