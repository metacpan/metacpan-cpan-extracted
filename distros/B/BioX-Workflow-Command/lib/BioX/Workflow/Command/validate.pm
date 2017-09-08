package BioX::Workflow::Command::validate;

use v5.10;

use MooseX::App::Command;
use namespace::autoclean;

extends 'BioX::Workflow::Command';
with 'BioX::Workflow::Command::Utils::Log';
with 'BioX::Workflow::Command::Utils::Files';

command_short_description 'Validate your workflow.';
command_long_description 'Validate your workflow.';

sub execute {
    my $self = shift;

    if(! $self->load_yaml_workflow){
      $self->app_log->warn('Exiting now.');
      return;
    }
}

__PACKAGE__->meta->make_immutable;

1;
