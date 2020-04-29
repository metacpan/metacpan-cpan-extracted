package Data::Object::String::Func::Replace;

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
  req => 1
);

has arg3 => (
  is => 'ro',
  isa => 'StringLike',
  req => 1
);

has arg4 => (
  is => 'ro',
  isa => 'StringLike',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $search, $replace, $flags) = $self->unpack;

  my $result = "$data";
  my $regexp = UNIVERSAL::isa($search, 'Regexp');

  $flags = defined($flags) ? $flags : '';
  $search = quotemeta($search) if $search and !$regexp;

  local $@;
  eval("sub { \$_[0] =~ s/$search/$replace/$flags }")->($result);

  return $result;
}

sub mapping {
  return ('arg1', 'arg2', 'arg3', 'arg4');
}

1;
