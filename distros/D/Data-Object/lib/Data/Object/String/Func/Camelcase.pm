package Data::Object::String::Func::Camelcase;

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

  my $result = ucfirst(lc("$data"));

  $result =~ s/[^a-zA-Z0-9]+([a-z])/\U$1/g;
  $result =~ s/[^a-zA-Z0-9]+//g;

  return $result;
}

sub mapping {
  return ('arg1');
}

1;
