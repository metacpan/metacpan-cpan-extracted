package Bio::VertRes::Config::Recipes::Roles::VirusRnaSeqExpression;
# ABSTRACT: Moose Role which creates the rna seq expression object


use Moose::Role;
use Bio::VertRes::Config::Pipelines::RnaSeqExpression;

sub add_virus_rna_seq_expression_config
{
  my ($self, $pipeline_configs_array) = @_;
  push(
      @{$pipeline_configs_array},
      Bio::VertRes::Config::Pipelines::RnaSeqExpression->new(
          database                       => $self->database,
          database_connect_file          => $self->database_connect_file,
          config_base                    => $self->config_base,
          root_base                      => $self->root_base,
          log_base                       => $self->log_base,
          overwrite_existing_config_file => $self->overwrite_existing_config_file,
          limits                         => $self->limits,
          reference                      => $self->reference,
          reference_lookup_file          => $self->reference_lookup_file,
          protocol                       => $self->protocol
      )
  );
  return ;
}


no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::Roles::VirusRnaSeqExpression - Moose Role which creates the rna seq expression object

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Moose Role which creates the rna seq expression object

   with 'Bio::VertRes::Config::Recipes::Roles::VirusRnaSeqExpression';

=head1 METHODS

=head2 add_rna_seq_expression_config

Method with takes in the pipeline config array and adds the rna seq expression config to it.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
