package Car::AbstractFactory;

use strict;

use Class::Interface;
abstract;

eval qq|
use Class::AccessorMaker {
  createdCars => [],
};
|;

if ( $@ ) {
  no strict 'refs';
  *{ __PACKAGE__ . "::createdCars" } = sub {
    my ( $self, $what ) = @_;

    if ( defined $what ) {
      $self->{$what} = $what;
    }

    return $self->{$what} || [];
  };
}

sub createCar;  # this is the abstract method

sub rememberCreatedCar {
  my ( $self, $car ) = @_;

  push @{$self->createdCars}, $car;
}

1;
