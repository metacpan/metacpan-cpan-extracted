package Bio::MLST::ProcessFasta;
# ABSTRACT: Take in a fasta file, lookup the MLST database and create relevant files.
$Bio::MLST::ProcessFasta::VERSION = '2.1.1706216';


use Moose;
use Bio::MLST::SearchForFiles;
use Bio::MLST::CompareAlleles;
use Bio::MLST::SequenceType;
use Bio::MLST::OutputFasta;
use Bio::MLST::Spreadsheet::Row;
use Bio::MLST::Types;

has 'species'             => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'base_directory'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'fasta_file'          => ( is => 'ro', isa => 'Bio::MLST::File',      required => 1 ); 
has 'makeblastdb_exec'    => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'blastn_exec'         => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_directory'    => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_fasta_files'  => ( is => 'ro', isa => 'Bool',  default  => 0 ); 
has 'show_contamination_instead_of_alt_matches' => ( is => 'ro', isa => 'Bool',   default => 1 ); 
has 'report_lowest_st'  => ( is => 'ro', isa => 'Bool', default => 0 );

has '_search_results'     => ( is => 'ro', isa => 'Bio::MLST::SearchForFiles',  lazy => 1, builder => '_build__search_results' ); 
has '_compare_alleles'    => ( is => 'ro', isa => 'Bio::MLST::CompareAlleles',  lazy => 1, builder => '_build__compare_alleles' ); 
has '_sequence_type_obj'  => ( is => 'ro', isa => 'Bio::MLST::SequenceType',    lazy => 1, builder => '_build__sequence_type_obj' ); 
has '_spreadsheet_row_obj' => ( is => 'ro', isa => 'Bio::MLST::Spreadsheet::Row',    lazy => 1, builder => '_build__spreadsheet_row_obj' ); 

has 'concat_name'       => ( is => 'rw', isa => 'Maybe[Str]' );
has 'concat_sequence'   => ( is => 'rw', isa => 'Maybe[Str]' );

sub _build__search_results
{
  my($self) = @_;
  Bio::MLST::SearchForFiles->new(
    species_name   => $self->species,
    base_directory => $self->base_directory
  );
}

sub _build__compare_alleles
{
  my($self) = @_;
  my $compare_alleles = Bio::MLST::CompareAlleles->new(
    sequence_filename => $self->fasta_file,
    allele_filenames  => $self->_search_results->allele_filenames(),
    makeblastdb_exec  => $self->makeblastdb_exec,
    blastn_exec       => $self->blastn_exec,
    profiles_filename => $self->_search_results->profiles_filename()
  );
  
  my $output_fasta = Bio::MLST::OutputFasta->new(
    matching_sequences     => $compare_alleles->matching_sequences,
    non_matching_sequences => $compare_alleles->non_matching_sequences,
    output_directory       => $self->output_directory,
    input_fasta_file       => $self->fasta_file
  );
  $output_fasta->create_files();
  $self->concat_name($output_fasta->_fasta_filename);
  $self->concat_sequence($output_fasta->concat_sequence);
  return $compare_alleles;
}

sub _build__sequence_type_obj
{
  my($self) = @_;
  my $sequence_type_obj = Bio::MLST::SequenceType->new(
    profiles_filename  => $self->_search_results->profiles_filename(),
    matching_names     => $self->_compare_alleles->found_sequence_names,
    non_matching_names => $self->_compare_alleles->found_non_matching_sequence_names,
    report_lowest_st   => $self->report_lowest_st
  );
}

sub _build__spreadsheet_row_obj
{
  my($self) = @_;
  Bio::MLST::Spreadsheet::Row->new(
    sequence_type_obj => $self->_sequence_type_obj, 
    compare_alleles   => $self->_compare_alleles,
    show_contamination_instead_of_alt_matches => $self->show_contamination_instead_of_alt_matches
  );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::ProcessFasta - Take in a fasta file, lookup the MLST database and create relevant files.

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

Take in a fasta file, lookup the MLST database and create relevant files.

   use Bio::MLST::ProcessFasta;
   Bio::MLST::ProcessFasta->new(
     'species'           => 'E.coli',
     'base_directory'    => '/path/to/dir',
     'fasta_file'        => 'myfasta.fa',
     'makeblastdb_exec'  => 'makeblastdb',
     'blastn_exec'       => 'blastn',
     'output_directory'  => '/path/to/output',
     'output_fasta_files'=> 1,
   );

=head1 METHODS

=head2 concat_name

Output the name of the concatinated multifasta file

=head2 concat_sequence

Output the sequences of the concatinated multifasta file

=head2 _spreadsheet_row_obj

A row in the output spreadsheet

=head1 SEE ALSO

=over 4

=item *

L<Bio::MLST::Check>

=back

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
