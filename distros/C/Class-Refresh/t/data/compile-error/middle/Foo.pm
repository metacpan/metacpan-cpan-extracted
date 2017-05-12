package Foo;
use Moose;

has bar => (is => 'ro');

sub meth { $error; 2 }

no Moose;

1;
