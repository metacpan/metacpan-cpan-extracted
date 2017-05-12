package Foo;
use Moose;

has foo => (is => 'ro');

sub meth { 1 }

no Moose;

1;
