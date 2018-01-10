package BioX::Workflow::Command::inspect::Exceptions::Path;

use Moose;
use namespace::autoclean;

extends 'BioX::Workflow::Command::Exceptions';

sub BUILD {
  my $self = shift;
  $self->message('Path specification is incorrect.');
}

1;
