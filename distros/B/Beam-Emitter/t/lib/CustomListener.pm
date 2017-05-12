package CustomListener;

use Moo;
extends 'Beam::Listener';

has attr => ( is => 'ro', required => 1 );

1;

