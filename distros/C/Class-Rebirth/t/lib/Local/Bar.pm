package Local::Bar;

use strict;

use Local::More;


sub new{
  my $pkg = shift;
  my $first = shift;

  my $self = bless {@_}, $pkg;

  $self->{'more'} = Local::More->new();

  return $self;
}


sub methodA{
  return 'A';
}

sub methodB{
  return 'B';
}


1;