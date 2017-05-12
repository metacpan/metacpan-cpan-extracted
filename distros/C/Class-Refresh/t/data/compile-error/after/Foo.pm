package Foo;
use Moose;

has bar => (is => 'ro');

sub meth { my $error; 3 }

no Moose;

1;
