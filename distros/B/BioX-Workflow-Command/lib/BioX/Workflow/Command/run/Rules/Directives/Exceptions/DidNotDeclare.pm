package BioX::Workflow::Command::run::Rules::Directives::Exceptions::DidNotDeclare;

use Moose;
use namespace::autoclean;

extends 'BioX::Workflow::Command::Exceptions';

sub BUILD {
  my $self = shift;
}

1;
