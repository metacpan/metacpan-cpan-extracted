package Data::Object::Hash::Func::Merge;

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
  isa => 'ArrayRef[Any]',
  opt => 1
);

# METHODS

sub clone {
  require Storable;

  return Storable::dclone(pop);
}

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  if (!@args) {
    return $self->clone($data);
  }

  if (@args > 1) {
    return $self->clone($self->recurse($data, $self->recurse(@args)));
  }

  my ($right) = @args;
  my (%merge) = %$data;

  for my $key (keys %$right) {
    my $lprop = $$data{$key};
    my $rprop = $$right{$key};

    $merge{$key}
      = ((ref($rprop) eq 'HASH') and (ref($lprop) eq 'HASH'))
      ? $self->recurse($$data{$key}, $$right{$key})
      : $$right{$key};
  }

  return $self->clone(\%merge);
}

sub mapping {
  return ('arg1', '@args');
}

1;
