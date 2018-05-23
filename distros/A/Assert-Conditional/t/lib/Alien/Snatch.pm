package 
    Alien::Snatch;

use Moose::Role;

requires "our_data";

sub roll_data {
    my($self, @args) = @_;
    $self->our_data(@args);
}

1;
