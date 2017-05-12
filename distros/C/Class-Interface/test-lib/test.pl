#!/usr/bin/perl -l

use strict;

BEGIN {
  unshift @INC, "./lib", "./test-lib";
}

use Car::Factory;

my $factory = new Car::Factory;

foreach my $car ( qw(fiat ford mercedes) ) {
  print "-- " . uc($car) . ":";
  my $c = $factory->createCar($car);

  $c->openDoors & $c->closeDoors;
  $c->start;

  if ( $c->isa("Car::Runnable") ) {
    local $\ = "";
    print ("-- we can run the car!\n  ") & $c->run;
    print "\n\n";
  }

  $c->stop;

  $c->openDoors & $c->closeDoors;
  print "\n";
}

if ( $factory->isa("Car::AFactory") ) {
  print join(", ", @{$factory->createdCars});
}