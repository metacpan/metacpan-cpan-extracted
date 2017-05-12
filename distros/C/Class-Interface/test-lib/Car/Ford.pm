package Car::Ford;

use Class::Interface;
implements qw(Car::Interface Car::Runnable);

sub new {
  my $class = ref($_[0]) || $_[0]; shift;

  return bless( {}, $class );
}

sub openDoors { print "Doors open smoothly" }
sub closeDoors { print "Doors close smoothly" }
sub start { print "*pruttel pruttel* vroem." }
sub run { print "Look... Moving fordward ;->"}
sub stop { print "*uch*" }

1;
