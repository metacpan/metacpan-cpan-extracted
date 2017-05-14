package Bio::VertRes::Config::Recipes::Roles::VirusSnpCalling;
# ABSTRACT: Moose Role which creates the virus snp calling object


use Moose::Role;
use Bio::VertRes::Config::Pipelines::SnpCalling;

sub add_virus_snp_calling_config
{
  my ($self, $pipeline_configs_array) = @_;
  push(
      @{$pipeline_configs_array},
      Bio::VertRes::Config::Pipelines::SnpCalling->new(
          database                       => $self->database,
          database_connect_file          => $self->database_connect_file,
          config_base                    => $self->config_base,
          root_base                      => $self->root_base,
          log_base                       => $self->log_base,
          overwrite_existing_config_file => $self->overwrite_existing_config_file,
          limits                         => $self->limits,
          reference                      => $self->reference,
          reference_lookup_file          => $self->reference_lookup_file
      )
  );
  return ;
}


no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::Roles::VirusSnpCalling - Moose Role which creates the virus snp calling object

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Moose Role which creates the virus snp calling object

   with 'Bio::VertRes::Config::Recipes::Roles::VirusSnpCalling';

=head1 METHODS

=head2 add_virus_snp_calling_config

Method with takes in the pipeline config array and adds the virus snp calling config to it.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
