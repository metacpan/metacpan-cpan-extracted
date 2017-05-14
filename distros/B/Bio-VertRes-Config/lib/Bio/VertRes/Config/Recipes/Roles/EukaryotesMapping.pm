package Bio::VertRes::Config::Recipes::Roles::EukaryotesMapping;
# ABSTRACT: Moose Role which creates the Euk mapping  objects


use Moose::Role;
use Bio::VertRes::Config::Pipelines::BwaMapping;
use Bio::VertRes::Config::Pipelines::Ssaha2Mapping;
use Bio::VertRes::Config::Pipelines::StampyMapping;
use Bio::VertRes::Config::Pipelines::TophatMapping;
use Bio::VertRes::Config::Pipelines::Bowtie2Mapping;

sub add_eukaryotes_bwa_mapping_config
{
  my ($self, $pipeline_configs_array) = @_;
  push(
      @{$pipeline_configs_array},
      Bio::VertRes::Config::Pipelines::BwaMapping->new(
          database                       => $self->database,
          database_connect_file          => $self->database_connect_file,
          config_base                    => $self->config_base,
          root_base                      => $self->root_base,
          log_base                       => $self->log_base,
          overwrite_existing_config_file => $self->overwrite_existing_config_file,
          limits                         => $self->limits,
          reference                      => $self->reference,
          reference_lookup_file          => $self->reference_lookup_file,
      )
  );
  return ;
}

sub add_eukaryotes_bowtie2_mapping_config
{
  my ($self, $pipeline_configs_array) = @_;
  push(
      @{$pipeline_configs_array},
          Bio::VertRes::Config::Pipelines::Bowtie2Mapping->new(
              database                       => $self->database,
              database_connect_file          => $self->database_connect_file,
              config_base                    => $self->config_base,
              root_base                      => $self->root_base,
              log_base                       => $self->log_base,
              overwrite_existing_config_file => $self->overwrite_existing_config_file,
              limits                         => $self->limits,
              reference                      => $self->reference,
              reference_lookup_file          => $self->reference_lookup_file,

          )
      );
  return ;
}


sub add_eukaryotes_ssaha2_mapping_config
{
  my ($self, $pipeline_configs_array) = @_;
  push(
      @{$pipeline_configs_array},
          Bio::VertRes::Config::Pipelines::Ssaha2Mapping->new(
              database                       => $self->database,
              database_connect_file          => $self->database_connect_file,
              config_base                    => $self->config_base,
              root_base                      => $self->root_base,
              log_base                       => $self->log_base,
              overwrite_existing_config_file => $self->overwrite_existing_config_file,
              limits                         => $self->limits,
              reference                      => $self->reference,
              reference_lookup_file          => $self->reference_lookup_file,

          )
      );
  return ;
}

sub add_eukaryotes_tophat_mapping_config
{
  my ($self, $pipeline_configs_array) = @_;
  push(
      @{$pipeline_configs_array},
    Bio::VertRes::Config::Pipelines::TophatMapping->new(
        database                       => $self->database,
        database_connect_file          => $self->database_connect_file,
        config_base                    => $self->config_base,
        root_base                      => $self->root_base,
        log_base                       => $self->log_base,
        overwrite_existing_config_file => $self->overwrite_existing_config_file,
        limits                         => $self->limits,
        reference                      => $self->reference,
        reference_lookup_file          => $self->reference_lookup_file,
        additional_mapper_params       => $self->additional_mapper_params,
          )
      );
  return ;
}


sub add_eukaryotes_stampy_mapping_config
{
  my ($self, $pipeline_configs_array) = @_;
  push(
      @{$pipeline_configs_array},
          Bio::VertRes::Config::Pipelines::StampyMapping->new(
              database                       => $self->database,
              database_connect_file          => $self->database_connect_file,
              config_base                    => $self->config_base,
              root_base                      => $self->root_base,
              log_base                       => $self->log_base,
              overwrite_existing_config_file => $self->overwrite_existing_config_file,
              limits                         => $self->limits,
              reference                      => $self->reference,
              reference_lookup_file          => $self->reference_lookup_file,

          )
      );
  return ;
}


no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::Roles::EukaryotesMapping - Moose Role which creates the Euk mapping  objects

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Moose Role which creates the Euk mapping  objects

   with 'Bio::VertRes::Config::Recipes::Roles::EukaryotesMapping';

=head1 METHODS

=head2 add_eukaryotes_bwa_mapping_config

create the mapping config for bwa

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
