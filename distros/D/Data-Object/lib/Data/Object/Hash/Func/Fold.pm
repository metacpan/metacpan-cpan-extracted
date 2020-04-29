package Data::Object::Hash::Func::Fold;

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
  isa => 'StringLike',
  opt => 1
);

has arg3 => (
  is => 'ro',
  isa => 'HashLike',
  opt => 1
);

has arg4 => (
  is => 'ro',
  isa => 'HashLike',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $path, $store, $cache) = $self->unpack;

  my $folded = _folding($data, $path, $store, $cache);

  return $folded;
}

sub mapping {
  return ('arg1', 'arg2', 'arg3', 'arg4');
}

# PRIVATE

sub _folding {
  my ($data, $path, $store, $cache) = @_;

  $store ||= {};
  $cache ||= {};

  my $ref = ref($data);
  my $obj = Scalar::Util::blessed($data);
  my $adr = Scalar::Util::refaddr($data);
  my $tmp = {%$cache};

  if ($adr && $tmp->{$adr}) {
    $store->{$path} = $data;
  } elsif ($ref eq 'HASH' || ($obj and $obj->isa('Data::Object::Hash'))) {
    $tmp->{$adr} = 1;
    if (%$data) {
      for my $key (sort(keys %$data)) {
        my $place = $path ? join('.', $path, $key) : $key;
        my $value = $data->{$key};
        _folding($value, $place, $store, $tmp);
      }
    } else {
      $store->{$path} = {};
    }
  } elsif ($ref eq 'ARRAY' || ($obj and $obj->isa('Data::Object::Array'))) {
    $tmp->{$adr} = 1;
    if (@$data) {
      for my $idx (0 .. $#$data) {
        my $place = $path ? join(':', $path, $idx) : $idx;
        my $value = $data->[$idx];
        _folding($value, $place, $store, $tmp);
      }
    } else {
      $store->{$path} = [];
    }
  } else {
    $store->{$path} = $data if $path;
  }

  return $store;
}

1;
