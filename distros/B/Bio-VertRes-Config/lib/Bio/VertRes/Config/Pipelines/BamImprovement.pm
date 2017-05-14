package Bio::VertRes::Config::Pipelines::BamImprovement;

# ABSTRACT: The base class for the bam improvement pipeline.


use Moose;
use Bio::VertRes::Config::Pipelines::Common;
use Bio::VertRes::Config::References;
use Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter;
use Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix;
extends 'Bio::VertRes::Config::Pipelines::Common';
with 'Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter';
with 'Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix';
with 'Bio::VertRes::Config::Pipelines::Roles::FilenameWithReference';

has 'pipeline_short_name' => ( is => 'ro', isa => 'Str', default  => 'improvement' );
has 'module'              => ( is => 'ro', isa => 'Str', default  => 'VertRes::Pipelines::BamImprovement::NonHuman' );
has 'reference'           => ( is => 'ro', isa => 'Str', required => 1 );
has 'reference_lookup_file' => ( is => 'ro', isa => 'Str', required => 1);
has 'toplevel_action'      => ( is => 'ro', isa => 'Str', default => '__VRTrack_BamImprovement__' );

has 'slx_mapper'               => ( is => 'ro', isa => 'Str',  default => 'smalt' );
has '_reference_fasta'         => ( is => 'ro', isa => 'Str',  lazy    => 1, builder => '_build__reference_fasta' );
has '_keep_original_bam_files' => ( is => 'ro', isa => 'Bool', default => 0 );
has '_ignore_bam_improvement_status' => ( is => 'ro', isa => 'Int', default => 1 );

sub _build__reference_fasta {
    my ($self) = @_;
    Bio::VertRes::Config::References->new( reference_lookup_file => $self->reference_lookup_file )
      ->get_reference_location_on_disk( $self->reference );
}

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();
    $output_hash->{limits}                  = $self->_escaped_limits;
    
    $output_hash->{vrtrack_processed_flags} = { import => 1, qc => 1, stored => 1, mapped => 1 };
    $output_hash->{data}{reference}         = $self->_reference_fasta;
    $output_hash->{data}{assembly_name}     = $self->reference;
    $output_hash->{data}{slx_mapper}        = $self->slx_mapper;
    $output_hash->{data}{keep_original_bam_files} = $self->_keep_original_bam_files;
    $output_hash->{data}{ignore_bam_improvement_status} = $self->_ignore_bam_improvement_status;
    return $output_hash;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::BamImprovement - The base class for the bam improvement pipeline.

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

The base class for the bam improvement pipeline.
   use Bio::VertRes::Config::Pipelines::BamImprovement;

   my $pipeline = Bio::VertRes::Config::Pipelines::BamImprovement->new(
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
