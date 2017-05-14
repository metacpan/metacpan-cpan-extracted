package Bio::VertRes::Config::Recipes::BacteriaRnaSeqExpressionUsingSmalt;
# ABSTRACT: Standard snp calling pipeline for bacteria


use Moose;
use Bio::VertRes::Config::Pipelines::QC;
use Bio::VertRes::Config::Pipelines::SmaltMapping;
use Bio::VertRes::Config::Pipelines::RnaSeqExpression;
use Bio::VertRes::Config::RegisterStudy;
extends 'Bio::VertRes::Config::Recipes::Common';
with 'Bio::VertRes::Config::Recipes::Roles::RegisterStudy';
with 'Bio::VertRes::Config::Recipes::Roles::Reference';
with 'Bio::VertRes::Config::Recipes::Roles::CreateGlobal';
with 'Bio::VertRes::Config::Recipes::Roles::BacteriaRnaSeqExpression';

has 'protocol'  => ( is => 'ro', isa => 'Str',  default => 'StrandSpecificProtocol' );

has 'additional_mapper_params' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'mapper_index_params'      => ( is => 'ro', isa => 'Maybe[Str]' );

override '_pipeline_configs' => sub {
    my ($self) = @_;
    my @pipeline_configs;
    
    $self->add_qc_config(\@pipeline_configs);
    
    push(
        @pipeline_configs,
        Bio::VertRes::Config::Pipelines::SmaltMapping->new(
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
            mapper_index_params            => $self->mapper_index_params
        )
    );
    
    $self->add_bacteria_rna_seq_expression_config(\@pipeline_configs);
    
    return \@pipeline_configs;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::BacteriaRnaSeqExpressionUsingSmalt - Standard snp calling pipeline for bacteria

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

RNA seq expression with SMALT
   use Bio::VertRes::Config::Recipes::BacteriaRnaSeqExpressionUsingSmalt;

   my $obj = Bio::VertRes::Config::Recipes::BacteriaRnaSeqExpressionUsingSmalt->new( 
     database => 'abc', 
     limits => {project => ['Study ABC']}, 
     reference => 'ABC', 
     reference_lookup_file => '/path/to/refs.index',
     additional_mapper_params => '',
     mapper_index_params => '',
     protocol => 'StrandSpecificProtocol'
     );
   $obj->create;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
