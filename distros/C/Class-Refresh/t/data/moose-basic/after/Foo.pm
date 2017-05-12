package Foo;
use Moose;

has bar => (is => 'ro');

sub other_meth { }

no Moose;

1;
