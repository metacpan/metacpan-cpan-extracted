package BioX::Workflow::Command::run;

use v5.10;
use MooseX::App::Command;

extends 'BioX::Workflow::Command';
use BioX::Workflow::Command::Utils::Traits qw(ArrayRefOfStrs);
use BioX::Workflow::Command::run::Utils::Directives;

with 'BioX::Workflow::Command::run::Utils::Samples';
with 'BioX::Workflow::Command::run::Utils::Attributes';
with 'BioX::Workflow::Command::run::Utils::Rules';
with 'BioX::Workflow::Command::run::Utils::WriteMeta';
with 'BioX::Workflow::Command::run::Utils::Files::TrackChanges';
with 'BioX::Workflow::Command::run::Utils::Files::ResolveDeps';
with 'BioX::Workflow::Command::Utils::Log';
with 'BioX::Workflow::Command::Utils::Files';
with 'BioX::Workflow::Command::Utils::Plugin';

command_short_description 'Run your workflow';
command_long_description
  'Run your workflow, process the variables, and create all your directories.';

=head1 BioX::Workflow::Command::run

This is the main class of the `biox-workflow.pl run` command.

=cut


=head2 Attributes

=cut

=head2 Subroutines

=cut

sub execute {
    my $self = shift;

    $self->app_log->info('Printing out file info for '.$self->workflow);
    $self->print_opts;
    if(! $self->load_yaml_workflow){
      $self->app_log->warn('Exiting now.');
      return;
    }
    $self->apply_global_attributes;
    $self->get_global_keys;
    $self->get_samples;

    $self->write_workflow_meta('start');

    $self->iterate_rules;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
