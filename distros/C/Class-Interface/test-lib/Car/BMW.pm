package Car::BMW;

use strict;

use Class::AccessorMaker {
  speed => "",
};

use Class::Interface;

&extends( 'Car::Runner' );
&implements( 'Car::Interface', 'Car::Runnable' );

use base qw(Car::German);

sub openDoors {
	print "Doors open upwards -- this ist eine Gullwing :->";
}
sub closeDoors {
	print "Doors close downwards"
}

sub runCar {
  my ( $self ) = @_;
  my $speed = $self->speed || 120;

  return "Look... I am flying over the german speeeeeedways @ $speed kmh"
}