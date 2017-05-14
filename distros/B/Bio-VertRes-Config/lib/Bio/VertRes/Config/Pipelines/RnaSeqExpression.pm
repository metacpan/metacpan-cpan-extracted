package Bio::VertRes::Config::Pipelines::RnaSeqExpression;

# ABSTRACT: The base class for the RNA seq expression and TraDis pipeline.


use Moose;
use Bio::VertRes::Config::Pipelines::Common;
use Bio::VertRes::Config::References;
use Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter;
use Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix;
extends 'Bio::VertRes::Config::Pipelines::Common';
with 'Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter';
with 'Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix';
with 'Bio::VertRes::Config::Pipelines::Roles::FilenameWithReference';

has 'pipeline_short_name' => ( is => 'ro', isa => 'Str', default  => 'rna_seq' );
has 'module'              => ( is => 'ro', isa => 'Str', default  => 'VertRes::Pipelines::RNASeqExpression' );
has 'reference'           => ( is => 'ro', isa => 'Str', required => 1 );
has 'reference_lookup_file' =>  ( is => 'ro', isa => 'Str', required => 1 );
has 'toplevel_action'       => ( is => 'ro', isa => 'Str', default => '__VRTrack_RNASeqExpression__' );

has '_annotation_file'             => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__annotation_file' );
has '_sequencing_file_suffix'      => ( is => 'ro', isa => 'Str',  default => 'markdup.bam' );
has 'protocol'                     => ( is => 'ro', isa => 'Str',  required => 1 );
has '_mapping_quality'             => ( is => 'ro', isa => 'Int',  default => 1 );
has '_intergenic_regions'          => ( is => 'ro', isa => 'Bool', default => 1 );
has '_ignore_rnaseq_called_status' => ( is => 'ro', isa => 'Bool', default => 1 );

sub _build__annotation_file {
    my ($self) = @_;
    my $reference_file = Bio::VertRes::Config::References->new( reference_lookup_file => $self->reference_lookup_file )
      ->get_reference_location_on_disk( $self->reference );
    $reference_file =~ s!\.fa$!.gff!i;
    return $reference_file;
}

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();

    $output_hash->{vrtrack_processed_flags} = { import => 1, stored => 1, mapped => 1 };
    $output_hash->{limits} = $self->_escaped_limits;

    $output_hash->{data}{sequencing_file_suffix}      = $self->_sequencing_file_suffix;
    $output_hash->{data}{protocol}                    = $self->protocol;
    $output_hash->{data}{annotation_file}             = $self->_annotation_file;
    $output_hash->{data}{mapping_quality}             = $self->_mapping_quality;
    $output_hash->{data}{intergenic_regions}          = $self->_intergenic_regions;
    $output_hash->{data}{ignore_rnaseq_called_status} = $self->_ignore_rnaseq_called_status;

    return $output_hash;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::RnaSeqExpression - The base class for the RNA seq expression and TraDis pipeline.

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

The base class for the RNA seq expression and TraDis pipeline.
   use Bio::VertRes::Config::Pipelines::RnaSeqExpression;

   my $pipeline = Bio::VertRes::Config::Pipelines::RnaSeqExpression->new(
     database => 'abc',
     reference => 'Staphylococcus_aureus_subsp_aureus_ABC_v1',
     limits => {
       project => ['ABC study'],
       species => ['EFG']
     }

     );
   $pipeline->to_hash();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
