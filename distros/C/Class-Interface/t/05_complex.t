#!perl -wT

use strict;

BEGIN {
  ($ENV{PWD}) = $ENV{PWD} =~ /(.*)/;
  require "$ENV{PWD}/test-lib/setup.pl";
}

# test a class that both extends and implements and uses to extend to
# implement.
#
# AND; it uses Class::AccessorMaker to fulfill the abstract needs :->
#

use Test::More tests => 5;

eval "use Class::AccessorMaker { foo => 'bar' };";
SKIP: {
  skip "No Class::AccessorMaker available", 5 if $@;

  # get a BMW by factory
  use_ok("Car::BMW");
  
  use Car::Factory;
  my $factory = Car::Factory->new();
  my $bmw = $factory->createCar("BMW");
  can_ok($bmw, "runCar");
  can_ok($bmw, "speed");

  $bmw->speed(240);
  is( $bmw->speed, 240, "The speed is just right" );
  like( $bmw->runCar(), qr/ways \@ 240 kmh/, "It runs at the right speed" );
}

1;

