package Bio::VertRes::Config::Pipelines::QC;

# ABSTRACT: A class for generating the QC pipeline config file. This is done on a per study basis ususally (and filtered by species).


use Moose;
use Bio::VertRes::Config::Pipelines::Common;
use Bio::VertRes::Config::References;
use Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter;
extends 'Bio::VertRes::Config::Pipelines::Common';
with 'Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter';

has 'pipeline_short_name'   => ( is => 'ro', isa => 'Str', default  => 'qc' );
has 'module'                => ( is => 'ro', isa => 'Str', default  => 'VertRes::Pipelines::TrackQC_Fastq' );
has 'reference'             => ( is => 'ro', isa => 'Str', required => 1 );
has 'reference_lookup_file' => ( is => 'ro', isa => 'Str', required => 1 );
has 'toplevel_action'       => ( is => 'ro', isa => 'Str', default => '__VRTrack_QC__' );

has '_max_failures'         => ( is => 'ro', isa => 'Int', default => 3 );
has '_bwa_ref'              => ( is => 'ro', isa => 'Str', lazy    => 1, builder => '_build__bwa_ref' );
has '_fa_ref'               => ( is => 'ro', isa => 'Str', lazy    => 1, builder => '_build__fa_ref' );
has '_fai_ref'              => ( is => 'ro', isa => 'Str', lazy    => 1, builder => '_build__fai_ref' );
has '_stats_ref'            => ( is => 'ro', isa => 'Str', lazy    => 1, builder => '_build__stats_ref' );
has '_mapper'               => ( is => 'ro', isa => 'Str', default => 'bwa' );
has '_bwa_exec'             => ( is => 'ro', isa => 'Str', default => '/software/pathogen/external/apps/usr/local/bwa-0.6.1/bwa' );
has '_samtools'             => ( is => 'ro', isa => 'Str', default => '/software/pathogen/external/apps/usr/bin/samtools' );
has '_glf'                  => ( is => 'ro', isa => 'Str', default => '/software/pathogen/external/apps/usr/bin/glf' );
has '_mapviewdepth'         => ( is => 'ro', isa => 'Str', default => '/software/pathogen/external/apps/usr/bin/bindepth' );
has '_adapters'             => ( is => 'ro', isa => 'Str', default => '/lustre/scratch108/pathogen/pathpipe/usr/share/solexa-adapters.fasta' );
has '_snps'                 => ( is => 'ro', isa => 'Str', default => '/lustre/scratch108/pathogen/pathpipe/usr/share/mousehapmap.snps.bin' );
has '_skip_genotype'        => ( is => 'ro', isa => 'Int', default => 1 );
has '_gtype_confidence'     => ( is => 'ro', isa => 'Num', default => 1.2 );
has '_chr_regex'            => ( is => 'ro', isa => 'Str', default => '.*' );
has '_do_samtools_rmdup'    => ( is => 'ro', isa => 'Int', default => 1 );
has '_gcdepth_R'            => ( is => 'ro', isa => 'Str', default => '/software/pathogen/external/apps/usr/local/gcdepth/gcdepth.R' );




sub _build__bwa_ref {
    my ($self) = @_;
    return $self->_fa_ref;
}

sub _build__fa_ref {
    my ($self) = @_;
    Bio::VertRes::Config::References->new( reference_lookup_file => $self->reference_lookup_file )
      ->get_reference_location_on_disk( $self->reference );
}

sub _build__fai_ref {
    my ($self) = @_;
    return join( '.', ( $self->_fa_ref, 'fai' ) );
}

sub _build__stats_ref {
    my ($self) = @_;
    return join( '.', ( $self->_fa_ref, 'refstats' ) );
}

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();
    $output_hash->{data}{exit_on_errors} = 0;
    $output_hash->{max_failures}         = $self->_max_failures;
    $output_hash->{limits}               = $self->_escaped_limits;

    $output_hash->{data}{bwa_ref}           = $self->_bwa_ref;
    $output_hash->{data}{fa_ref}            = $self->_fa_ref;
    $output_hash->{data}{fai_ref}           = $self->_fai_ref;
    $output_hash->{data}{stats_ref}         = $self->_stats_ref;
    $output_hash->{data}{assembly}          = $self->reference;
    $output_hash->{data}{mapper}            = $self->_mapper;
    $output_hash->{data}{bwa_exec}          = $self->_bwa_exec;
    $output_hash->{data}{samtools}          = $self->_samtools;
    $output_hash->{data}{glf}               = $self->_glf;
    $output_hash->{data}{mapviewdepth}      = $self->_mapviewdepth;
    $output_hash->{data}{adapters}          = $self->_adapters;
    $output_hash->{data}{snps}              = $self->_snps;
    $output_hash->{data}{skip_genotype}     = $self->_skip_genotype;
    $output_hash->{data}{gtype_confidence}  = $self->_gtype_confidence;
    $output_hash->{data}{chr_regex}         = $self->_chr_regex;
    $output_hash->{data}{do_samtools_rmdup} = $self->_do_samtools_rmdup;
    $output_hash->{data}{gcdepth_R}         = $self->_gcdepth_R;

    return $output_hash;
};


sub _construct_filename
{
  my ($self, $suffix) = @_;
  my $output_filename = $self->_limits_values_part_of_filename();

  return $self->_filter_characters_truncate_and_add_suffix($output_filename,$suffix);
}

override 'log_file_name' => sub {
    my ($self) = @_;
    return $self->_construct_filename('log');
};

override 'config_file_name' => sub {
    my ($self) = @_;
    return $self->_construct_filename('conf');
};


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::QC - A class for generating the QC pipeline config file. This is done on a per study basis ususally (and filtered by species).

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A class for generating the QC pipeline config file.
   use Bio::VertRes::Config::Pipelines::QC;

   my $pipeline = Bio::VertRes::Config::Pipelines::QC->new(
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
