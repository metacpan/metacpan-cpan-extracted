package Car::Mercedes;

use Class::Interface;
implements 'Car::Interface', 'Car::Runnable';

use base 'Car::German';

sub new {
  return bless( {}, ref($_[0]) || $_[0] );
}

sub openDoors {
	print "Doors open upwards -- this ist eine Gullwing :->";
}
sub closeDoors {
	print "Doors close downwards"
}

sub run {
  print "Look... I am flying over the german speeeeeedways"
}

1;