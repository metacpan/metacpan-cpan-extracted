package Foo;
use Moose;

has baz => (is => 'ro');

sub other_other_meth { }

no Moose;

1;
