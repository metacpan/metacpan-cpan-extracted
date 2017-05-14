package Bio::AutomatedAnnotation;

# ABSTRACT: Automated annotation of assemblies


use Moose;
use File::Basename;
use Cwd;
use File::Temp;
use Bio::AutomatedAnnotation::Prokka;

has 'sample_name'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'dbdir'             => ( is => 'ro', isa => 'Str', required => 1 );
has 'assembly_file'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'annotation_tool'   => ( is => 'ro', isa => 'Str', default  => 'Prokka' );
has 'outdir'            => ( is => 'ro', isa => 'Str', default  => 'annotation' );
has 'tmp_directory'     => ( is => 'ro', isa => 'Str', default  => '/tmp' );
has 'sequencing_centre' => ( is => 'ro', isa => 'Str', default  => 'SC' );
has 'genus'             => ( is => 'ro', isa => 'Maybe[Str]' );
has 'accession_number'  => ( is => 'ro', isa => 'Maybe[Str]' );
has 'kingdom'           => ( is => 'ro', isa => 'Maybe[Str]' );
has 'cpus'              => ( is => 'ro', isa => 'Int', default => 1 );

has '_annotation_pipeline_class' =>
  ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__annotation_pipeline_class' );
has '_temp_directory_obj'  => ( is => 'ro', isa => 'File::Temp::Dir', lazy => 1, builder => '_build__temp_directory_obj' );
has '_temp_directory_name' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__temp_directory_name' );

sub _build__temp_directory_obj {
    my ($self) = @_;
    return File::Temp->newdir( DIR => $self->tmp_directory, CLEANUP => 1 );
}

sub _build__temp_directory_name {
    my ($self) = @_;
    return $self->_temp_directory_obj->dirname();
}

sub _contig_uniq_id {
    my ($self) = @_;
    if ( defined( $self->accession_number ) ) {
        return $self->accession_number;
    }
    else {
        return $self->sample_name;
    }
}

sub _build__annotation_pipeline_class {
    my ($self) = @_;
    my $annotation_pipeline_class = "Bio::AutomatedAnnotation::" . $self->annotation_tool;
    eval "require $annotation_pipeline_class";
    return $annotation_pipeline_class;
}

sub annotate {
    my ($self) = @_;

    # Run the annotation in the directory containing the assembly
    my $original_cwd = getcwd();
    my ( $filename, $directories, $suffix ) = fileparse( $self->assembly_file );
    chdir($directories);

    my $annotation_pipeline = $self->_annotation_pipeline_class->new(
        assembly_file  => $self->assembly_file,
        tempdir        => $self->_temp_directory_name,
        centre         => $self->sequencing_centre,
        dbdir          => $self->dbdir,
        prefix         => $self->sample_name,
        locustag       => $self->sample_name,
        outdir         => $self->outdir,
        force          => 1,
        contig_uniq_id => $self->_contig_uniq_id,
        cleanup_prod   => 0,
        cpus           => $self->cpus,
        rfam           => 1,
    );

    if ( defined( $self->genus ) ) {
        $annotation_pipeline->genus( $self->genus );
        $annotation_pipeline->usegenus(1);
    }
    
    if(defined($self->kingdom))
    {
      $annotation_pipeline->kingdom( $self->kingdom );
    }

    $annotation_pipeline->annotate;

    chdir($original_cwd);
    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation - Automated annotation of assemblies

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Automated annotation of assemblies.
   use Bio::AutomatedAnnotation;

   my $obj = Bio::AutomatedAnnotation->new(
     assembly_file    => $assembly_file,
     annotation_tool  => $annotation_tool,
     sample_name      => $lane_name,
     accession_number => $accession,
     dbdir            => $dbdir,
     tmp_directory    => $tmp_directory
   );
  $obj->annotate;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
