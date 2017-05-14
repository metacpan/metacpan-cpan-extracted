package Bio::VertRes::Config::Pipelines::SnpCalling;

# ABSTRACT: The base class for the SNP calling pipeline.


use Moose;
use Bio::VertRes::Config::Pipelines::Common;
use Bio::VertRes::Config::References;
use Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter;
use Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix;
extends 'Bio::VertRes::Config::Pipelines::Common';
with 'Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter';
with 'Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix';
with 'Bio::VertRes::Config::Pipelines::Roles::FilenameWithReference';

has 'pipeline_short_name' => ( is => 'ro', isa => 'Str', default  => 'snps' );
has 'module'              => ( is => 'ro', isa => 'Str', default  => 'VertRes::Pipelines::SNPs' );
has 'reference'           => ( is => 'ro', isa => 'Str', required => 1 );
has 'reference_lookup_file' =>  ( is => 'ro', isa => 'Str', required => 1 );
has 'toplevel_action'       => ( is => 'ro', isa => 'Str', default => '__VRTrack_SNPs__' );
has 'run_after_bam_improvement' => ( is => 'ro', isa => 'Bool', default => 0);

has '_max_lanes'     => ( is => 'ro', isa => 'Int',  default => 300 );
has '_pseudo_genome' => ( is => 'ro', isa => 'Bool', default => 1 );
has '_bam_suffix'    => ( is => 'ro', isa => 'Str',  default => 'markdup.bam' );

has '_bsub_opts' => (
    is      => 'ro',
    isa     => 'Str',
    default => "-q normal -M3500000 -R 'select[type==X86_64 && mem>3500] rusage[mem=3500,thouio=1,tmp=16000]'"
);
has '_bsub_opts_long' => (
    is      => 'ro',
    isa     => 'Str',
    default => "-q normal -M3500000 -R 'select[type==X86_64 && mem>3500] rusage[mem=3500,thouio=1,tmp=16000]'"
);
has '_bsub_opts_mpileup' =>
  ( is => 'ro', isa => 'Str', default => "-q normal -R 'select[type==X86_64] rusage[thouio=1]'" );
has '_split_size_mpileup'       => ( is => 'ro', isa => 'Int', default => 300000000 );
has '_tmp_dir'                  => ( is => 'ro', isa => 'Str', default => '/lustre/scratch108/pathogen/tmp' );
has '_mpileup_cmd'              => ( is => 'ro', isa => 'Str', default => 'samtools mpileup -d 1000 -DSug ' );
has '_max_jobs'                 => ( is => 'ro', isa => 'Int', default => 100 );
has '_fai_chr_regex'            => ( is => 'ro', isa => 'Str', default => '[\w\.\#]+' );
has '_fa_ref'                   => ( is => 'ro', isa => 'Str', lazy    => 1, builder => '_build__fa_ref' );
has '_fai_ref'                  => ( is => 'ro', isa => 'Str', lazy    => 1, builder => '_build__fai_ref' );
has '_ignore_snp_called_status' => ( is => 'ro', isa => 'Int', default => 1 );

sub _build__fa_ref {
    my ($self) = @_;
    Bio::VertRes::Config::References->new( reference_lookup_file => $self->reference_lookup_file )
      ->get_reference_location_on_disk( $self->reference );
}

sub _build__fai_ref {
    my ($self) = @_;
    return join( '.', ( $self->_fa_ref, 'fai' ) );
}

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();

    $output_hash->{max_lanes} = $self->_max_lanes;
    $output_hash->{vrtrack_processed_flags} = { import => 1, qc => 1, stored => 1, mapped => 1};
    $output_hash->{vrtrack_processed_flags}{improved} = 1 if($self->run_after_bam_improvement);

    if ( $self->_pseudo_genome ) {
        $output_hash->{data}{task} = 'pseudo_genome,mpileup,update_db,cleanup';
    }
    else {
        $output_hash->{data}{task} = 'mpileup,update_db,cleanup';
    }
    $output_hash->{data}{bam_suffix}               = $self->_bam_suffix;
    $output_hash->{data}{bsub_opts}                = $self->_bsub_opts;
    $output_hash->{data}{bsub_opts_long}           = $self->_bsub_opts_long;
    $output_hash->{data}{bsub_opts_mpileup}        = $self->_bsub_opts_mpileup;
    $output_hash->{data}{split_size_mpileup}       = $self->_split_size_mpileup;
    $output_hash->{data}{tmp_dir}                  = $self->_tmp_dir;
    $output_hash->{data}{mpileup_cmd}              = $self->_mpileup_cmd;
    $output_hash->{data}{max_jobs}                 = $self->_max_jobs;
    $output_hash->{data}{fai_chr_regex}            = $self->_fai_chr_regex;
    $output_hash->{data}{fa_ref}                   = $self->_fa_ref;
    $output_hash->{data}{fai_ref}                  = $self->_fai_ref;
    $output_hash->{data}{ignore_snp_called_status} = $self->_ignore_snp_called_status;
    $output_hash->{limits}               = $self->_escaped_limits;    
    return $output_hash;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::SnpCalling - The base class for the SNP calling pipeline.

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

he base class for the SNP calling pipeline.
   use Bio::VertRes::Config::Pipelines::SnpCalling;

   my $pipeline = Bio::VertRes::Config::Pipelines::Mapping->new(
     database => 'abc',
     reference => 'Staphylococcus_aureus_subsp_aureus_ABC_v1',
     limits => {
       project => ['ABC study'],
       species => ['EFG']
     },

     );
   $pipeline->to_hash();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
