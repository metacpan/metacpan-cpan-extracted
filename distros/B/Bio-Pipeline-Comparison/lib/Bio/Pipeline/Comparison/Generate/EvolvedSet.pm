package Bio::Pipeline::Comparison::Generate::EvolvedSet;

# ABSTRACT: Take in a reference genome and evolve it multiple times to produce multiple FASTA files and VCF files containing the differences to the original reference.


use Moose;
use File::Path qw(make_path);
use File::Basename;
use File::Copy;
use File::Find;
use Bio::SeqIO;
use IO::Zlib;
use Archive::Tar;
use Bio::Pipeline::Comparison::Generate::Evolve;

has 'input_filename'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'number_of_genomes' => ( is => 'ro', isa => 'Int', default  => 10 );
has 'output_directory'  => ( is => 'ro', isa => 'Str', lazy     => 1, builder => '_build_output_directory' );

has '_input_filename_base' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__input_filename_base' );
has '_vcfs_directory'      => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__vcfs_directory' );
has '_evolved_references_directory' =>
  ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__evolved_references_directory' );

has '_default_vcfs_directory_name'               => ( is => 'ro', isa => 'Str', default => 'vcfs' );
has '_default_evolved_references_directory_name' => ( is => 'ro', isa => 'Str', default => 'evolved_references' );

sub _build__input_filename_base {
    my ($self) = @_;
    my ( $base_filename, $directories, $suffix ) = fileparse( $self->input_filename, qr/\.[^.]*/ );
    return $base_filename;
}

sub _build_output_directory {
    my ($self) = @_;
    my ( $base_filename, $directories, $suffix ) = fileparse( $self->input_filename, qr/\.[^.]*/ );
    my $output_directory = $directories . $base_filename;
    make_path($output_directory) unless ( -d $output_directory );
    return $output_directory;
}

sub _build__vcfs_directory {
    my ($self) = @_;
    my $output_directory = join( '/', ( $self->output_directory, $self->_default_vcfs_directory_name ) );
    make_path($output_directory) unless ( -d $output_directory );
    return $output_directory;
}

sub _build__evolved_references_directory {
    my ($self) = @_;
    my $output_directory = join( '/', ( $self->output_directory, $self->_default_evolved_references_directory_name ) );
    make_path($output_directory) unless ( -d $output_directory );
    return $output_directory;
}

sub _create_multiple_evolved_genomes {
    my ($self) = @_;
    for ( my $i = 0 ; $i < $self->number_of_genomes ; $i++ ) {
      
        my $output_filename = join( '/',( $self->_evolved_references_directory, join( '.', ( $self->_input_filename_base, ( $i + 1 ), 'fa' ) ) ) );
        my $vcf_output_filename = join( '/',( $self->_vcfs_directory, join( '.', ( $self->_input_filename_base, ( $i + 1 ), 'vcf','gz' ) ) ) );

        Bio::Pipeline::Comparison::Generate::Evolve->new(
            input_filename      => $self->input_filename,
            output_filename     => $output_filename,
            vcf_output_filename => $vcf_output_filename
        )->evolve();

    }
}

sub _copy_the_reference_to_output_directory {
    my ($self) = @_;
    copy( $self->input_filename, $self->output_directory );
}

sub evolve {
    my ($self) = @_;
    $self->_copy_the_reference_to_output_directory;
    $self->_create_multiple_evolved_genomes();
    1;
}

sub create_archive {
    my ($self) = @_;
    
    my @filelist = ();
    find (sub { push @filelist, $File::Find::name }, $self->output_directory);
    
    Archive::Tar->create_archive( 
      join('.',($self->_input_filename_base,'tgz')), 
      COMPRESS_GZIP, 
      @filelist 
    );
    1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Pipeline::Comparison::Generate::EvolvedSet - Take in a reference genome and evolve it multiple times to produce multiple FASTA files and VCF files containing the differences to the original reference.

=head1 VERSION

version 1.123050

=head1 SYNOPSIS

Take in a reference genome and evolve it multiple times to produce multiple FASTA files and VCF files containing the differences to the original reference.

use Bio::Pipeline::Comparison::Generate::EvolvedSet;
my $obj = Bio::Pipeline::Comparison::Generate::EvolvedSet->new(
  input_filename   => 'reference.fa', 
  output_directory => 'genus_species',
  number_of_genomes => 100,
);
$obj->evolve;
$obj->create_archive;

=head1 METHODS

=head2 number_of_genomes

The number of different evolved genomes required. Each genome will have a FASTA file and a corresponding VCF file.

=head2 evolve

Evolve the genome and produce multiple versions of the reference.

=head2 create_archive

Create a tgz (tar and gzipped) archive of all the file.

=head1 SEE ALSO

=over 4

=item *

L<Bio::Pipeline::Comparison>

=item *

L<Bio::Pipeline::Comparison::Generate::Evolve>

=back

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
