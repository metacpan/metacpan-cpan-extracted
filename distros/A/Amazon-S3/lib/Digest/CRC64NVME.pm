package Digest::CRC64NVME;

use strict;
use warnings;

use Digest::CRC qw(crc);
use Math::BigInt;

use Readonly;

Readonly::Scalar my $WIDTH  => 64;
Readonly::Scalar my $POLY   => Math::BigInt->new('0xAD93D23594C93659');
Readonly::Scalar my $INIT   => Math::BigInt->new('0xFFFFFFFFFFFFFFFF');
Readonly::Scalar my $XOROUT => Math::BigInt->new('0xFFFFFFFFFFFFFFFF');
Readonly::Scalar my $REFIN  => 1;
Readonly::Scalar my $REFOUT => 1;

########################################################################
sub new {
########################################################################
  my ( $class, @data ) = @_;

  my $self = bless {}, $class;

  $self->reset;

  $self->add(@data)
    if @data;

  return $self;
}

########################################################################
sub reset {
########################################################################
  my ($self) = @_;

  $self->{crc}     = undef;
  $self->{started} = 0;

  return $self;
}

########################################################################
sub add {
########################################################################
  my ( $self, @data ) = @_;

  foreach my $data (@data) {
    $data //= q{};

    my $init
      = $self->{started}
      ? $self->{crc}
      : $INIT;

    $self->{crc} = crc( $data, $WIDTH, $init, $XOROUT, $REFOUT, $POLY, $REFIN, $self->{started} ? 1 : 0, );

    $self->{started} = 1;
  }

  return $self;
}

########################################################################
sub addfile {
########################################################################
  my ( $self, $fh ) = @_;

  while (1) {
    my $buffer;
    my $read = read $fh, $buffer, 32 * 1024;

    die "ERROR: read failed: $!\n"
      if !defined $read;

    last
      if !$read;

    $self->add($buffer);
  }

  return $self;
}

########################################################################
sub digest {
########################################################################
  my ($self) = @_;

  # The CRC of an empty message still needs to be calculated.
  $self->add(q{})
    if !$self->{started};

  my $hexdigest = sprintf '%016x', $self->{crc};

  $self->reset;

  return pack 'H*', $hexdigest;
}

########################################################################
sub hexdigest {
########################################################################
  my ($self) = @_;

  return uc unpack 'H*', $self->digest;
}

1;
