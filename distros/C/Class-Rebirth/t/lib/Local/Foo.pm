package Local::Foo;

use strict;
use Local::Bar;



sub new{
  my $pkg = shift;
  my $first = shift;

  my $self = bless {@_}, $pkg;

  $self->{'bar'} = Local::Bar->new();

  return $self;
}


sub method1{
  return 1;
}

sub method2{
  return 2;
}

1;