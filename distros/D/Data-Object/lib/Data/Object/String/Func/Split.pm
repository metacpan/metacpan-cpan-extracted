package Data::Object::String::Func::Split;

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
  isa => 'RegexpLike | StringLike',
  def => sub { qr() },
  opt => 1
);

has arg3 => (
  is => 'ro',
  isa => 'NumberLike',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $pattern, $limit) = $self->unpack;

  my $regexp = UNIVERSAL::isa($pattern, 'Regexp');

  $pattern = quotemeta($pattern) if $pattern and !$regexp;

  return [split(/$pattern/, "$data")] if !defined($limit);
  return [split(/$pattern/, "$data", $limit)];
}

sub mapping {
  return ('arg1', 'arg2', 'arg3');
}

1;
