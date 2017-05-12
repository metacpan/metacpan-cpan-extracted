package Car::Runner;


use Class::Interface;
&abstract();

sub runCar;
sub speed;

sub run {
  my ( $self ) = @_;

  $self->runCar;
}

1;