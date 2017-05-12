package Foo;
use Moose;

has foo => (is => 'ro');

sub meth { }

no Moose;

1;
