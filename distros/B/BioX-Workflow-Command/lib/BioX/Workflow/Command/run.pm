package BioX::Workflow::Command::run;

use v5.10;
use MooseX::App::Command;
use namespace::autoclean;

use File::Path qw(make_path);

extends 'BioX::Workflow::Command';
use BioSAILs::Utils::Traits qw(ArrayRefOfStrs);
use BioX::Workflow::Command::run::Rules::Directives;

with 'BioX::Workflow::Command::run::Utils::Samples';
with 'BioX::Workflow::Command::run::Utils::Attributes';
with 'BioX::Workflow::Command::run::Rules::Rules';
with 'BioX::Workflow::Command::run::Utils::WriteMeta';
with 'BioX::Workflow::Command::run::Utils::Files::TrackChanges';
with 'BioX::Workflow::Command::run::Utils::Files::ResolveDeps';
with 'BioX::Workflow::Command::Utils::Files';
with 'BioSAILs::Utils::Files::CacheDir';
with 'BioSAILs::Utils::CacheUtils';

command_short_description 'Run your workflow.';
command_long_description
  'Run your workflow, process the variables, and create all your directories.';

=head1 BioX::Workflow::Command::run

  biox run -h
  biox run -w variant_calling.yml

=cut

=head2 Attributes

=cut

=head2 Subroutines

=cut

sub execute {
    my $self = shift;

    if ( !$self->load_yaml_workflow ) {
        $self->app_log->warn('Exiting now.');
        return;
    }

    $self->print_opts;

    $self->app_log->info("Your cached workflow is available at\n\t".$self->cached_workflow."\n");
    $self->apply_global_attributes;
    $self->get_global_keys;
    $self->get_samples;

    $self->write_workflow_meta('start');

    $self->iterate_rules;
    
    $self->post_process_rules;
    $self->fh->close();
}


before 'BUILD' => sub {
    my $self = shift;

    make_path( $self->cache_dir );
    make_path( File::Spec->catdir( $self->cache_dir, '.biox-cache', 'logs' ) );
    make_path( File::Spec->catdir( $self->cache_dir, '.biox-cache', 'workflows' ) );
};

__PACKAGE__->meta->make_immutable;

1;
