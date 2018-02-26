package # hide from pause
  MyModule::OwnComponent;
use strict;
use warnings;

use MRO::Compat;
use mro 'c3';

sub message {
  my $self = shift;

  return join(" ", "OwnComponent", $self->next::method);
}

1;
