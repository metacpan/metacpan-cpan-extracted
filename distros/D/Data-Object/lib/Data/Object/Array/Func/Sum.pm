package Data::Object::Array::Func::Sum;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Array::Func';

our $VERSION = '2.05'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'ArrayLike',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data) = $self->unpack;

  my $sum = 0;

  for my $val (@$data) {
    if (!defined($val)) {
      next;
    } elsif (Scalar::Util::blessed($val)) {
      next if !overload::Method($val, q[""]);
    } elsif (!Scalar::Util::looks_like_number($val)) {
      next;
    }

    $sum += $val + 0;
  }

  return $sum;
}

sub mapping {
  return ('arg1');
}

1;
