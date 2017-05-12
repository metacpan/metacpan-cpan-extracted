package CORBA::IOP::TaggedProfile;

require 5.001;

use CORBA::IOP::Util;

use strict;


sub new {
  my $class = shift;
  my $self = {};

  $self->{version_major} = 0;
  $self->{version_minor} = 0;
  $self->{host} = 0;
  $self->{port} = 0;
  $self->{obj_key} = 0;

  return bless $self, $class;
}


sub parseIOR {
  my $self = shift;
  my ($ior, $byte, $little_endian) = @_;

  ($self->{version_major}, $byte) = &decode_number($ior, $byte, 1, $little_endian);
  ($self->{version_minor}, $byte) = &decode_number($ior, $byte, 1, $little_endian); 

  ($self->{host}, $byte) = &decode_string($ior, $byte, $little_endian); 

  ($self->{port}, $byte) = &decode_number($ior, $byte, 2, $little_endian); 

  ($self->{obj_key}, $byte) = &decode_encapsulation($ior, $byte, $little_endian); 
}


sub printHash {
  my $self = shift;
  my ($key, $value);

  while (($key, $value) = each %$self) {
    print "$key = $value\n";
  }
}


sub stringifyIOR {
  my $self = shift;
  my ($length, $little_endian) = @_;

  my ($ior);
  $ior = "";

  $ior .= encode_number($length + length($ior), 1, $little_endian, $self->{version_major});
  $ior .= encode_number($length + length($ior), 1, $little_endian, $self->{version_minor});

  $ior .= encode_string($length + length($ior), $little_endian, $self->{host});

  $ior .= encode_number($length + length($ior), 2, $little_endian, $self->{port});

  $ior .= encode_encapsulation($length + length($ior), $little_endian, $self->{obj_key});

  return $ior;
}


1;
