package Car::Fiat;

use Class::Interface;
implements 'Car::Interface';

sub new {
  my $class = ref($_[0]) || $_[0]; shift;
  return bless( {}, $class );
}


sub openDoors {
	print "Doors open in fiat style"
}
sub closeDoors {
	print "Doors close in fiat style"
}
sub start {
	print "Hey! Nothings happens"
}
sub stop {
	print "Still nothing happens - I was never started."
}

1;