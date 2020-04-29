package Data::Object::String::Func::Snakecase;

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

  my $result = "$data";

  my $re = qr/[\W_]+/;
  $result =~ s/$re/_/g;
  $result =~ s/^$re|$re$//g;

  return $result;
}

sub mapping {
  return ('arg1');
}

1;
