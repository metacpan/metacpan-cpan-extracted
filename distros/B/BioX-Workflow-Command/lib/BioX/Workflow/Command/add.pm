package BioX::Workflow::Command::add;

use v5.10;

use MooseX::App::Command;
use YAML;

extends 'BioX::Workflow::Command';

with 'BioX::Workflow::Command::Utils::Create';
with 'BioX::Workflow::Command::Utils::Files';
with 'BioX::Workflow::Command::Utils::Log';

command_short_description 'Create a new workflow';
command_long_description 'Create a new workflow';

=head1 BioX::Workflow::Command::add

This is the main class of the `biox-workflow.pl add` command.

=cut

=head2 Command Line Options

=cut

option '+outfile' => (
    default => sub {
        my $self     = shift;
        my $workflow = $self->workflow;
        return "$workflow";
    },
    documentation => 'Write your workflow to a file. The default will write it out to the same workflow.',
);

sub execute {
    my $self = shift;

    if(! $self->load_yaml_workflow){
      $self->app_log->warn('Exiting now.');
      return;
    }

    $self->app_log->info('Adding rules: '.join(', ', $self->all_rules));
    my $rules  = $self->add_rules;

    map { push(@{$self->workflow_data->{rules}}, $_ ) } @{$rules};

    $self->fh->print(Dump($self->workflow_data));
    $self->fh->close;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
