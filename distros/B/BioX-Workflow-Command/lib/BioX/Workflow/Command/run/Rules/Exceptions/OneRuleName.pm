package BioX::Workflow::Command::run::Rules::Exceptions::OneRuleName;

use Moose;
use namespace::autoclean;

extends 'BioX::Workflow::Command::Exceptions';

sub BUILD {
  my $self = shift;
  $self->message('There should be one rule per sequence under key \'rules\'');
}

__PACKAGE__->meta->make_immutable;

1;
