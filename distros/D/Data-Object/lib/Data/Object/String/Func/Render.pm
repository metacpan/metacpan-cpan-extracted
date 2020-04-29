package Data::Object::String::Func::Render;

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
  isa => 'HashLike',
  def => sub {{}},
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($string, $tokens) = $self->unpack;

  my $output = "$string";

  while (my($key, $value) = each(%$tokens)) {
    my $token = quotemeta "{$key}";

    $output =~ s/$token/$value/g;
  }

  return $output;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;
