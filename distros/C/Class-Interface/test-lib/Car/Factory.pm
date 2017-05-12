package Car::Factory;

use strict;

use Class::Interface;

&extends('Car::AbstractFactory');

use Car::Fiat;
use Car::Ford;
use Car::Mercedes;

# not using Car::BMW - it requires Class::AccessorMaker which you may
# not have.

sub new {
  return bless( {}, ref( $_[0] ) || $_[0] );
}

sub createCar {
  my ( $self, $car ) = @_;

  my $created;
  if ( lc($car) eq "fiat" ) {
    $created = Car::Fiat->new();

  } elsif ( lc($car) eq "ford" ) {
    $created = Car::Ford->new();

  } elsif ( lc($car) eq "mercedes" ) {
    $created = Car::Mercedes->new();

  } elsif ( lc($car) eq "bmw" ) {
    eval qq{ use Car::BMW };
    $created = Car::BMW->new() unless $@;

  } else {
    die "Cannot build cars of type $car (yet)";
  }

  $self->rememberCreatedCar($car);

  return $created;
}

1;
