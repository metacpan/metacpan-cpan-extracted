package Local::More;

use strict;



sub new{
  my $pkg = shift;
  my $first = shift;

  my $self = bless {@_}, $pkg;

  $self->{'m'}="me";

  return $self;
}


sub mo1{
  return "m1";
}

sub mo2{
  return "m2";
}

1;