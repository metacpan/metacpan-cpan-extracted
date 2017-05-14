package Bio::AutomatedAnnotation::GeneNameOccurances;

# ABSTRACT: Parse the gene names from multiple GFF files and provide a matrix of matches.


use Moose;
use Bio::Tools::GFF;
use Bio::AutomatedAnnotation::Exceptions;
use Bio::AutomatedAnnotation::GeneNamesFromGFF;

has 'gff_files'         => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'all_gene_names'    => ( is => 'ro', isa => 'HashRef',  lazy     => 1, builder => '_build_all_gene_names' );
has 'sorted_all_gene_names'    => ( is => 'ro', isa => 'ArrayRef',  lazy     => 1, builder => '_build_sorted_all_gene_names' );

has 'gene_name_hashes' => ( is => 'ro', isa => 'HashRef',  lazy     => 1, builder => '_build_gene_name_hashes' );
has 'number_of_files'   => ( is => 'ro', isa => 'Int',      lazy     => 1, builder => '_build_number_of_files' );

sub _build_sorted_all_gene_names
{
  my ($self) = @_;
  my %all_gene_names = %{$self->all_gene_names};
  
  my @sorted_gene_names = sort { $all_gene_names{$b} <=> $all_gene_names{$a} } keys %all_gene_names;
  return \@sorted_gene_names;
}

sub _build_number_of_files
{
  my ($self) = @_;
  return @{$self->gff_files};
}

sub _build_all_gene_names {
    my ($self) = @_;
    my %all_gene_names;
    
    for my $filename (keys %{$self->gene_name_hashes})
    {
      for my $gene_name (keys %{$self->gene_name_hashes->{$filename}})
      {
        $all_gene_names{$gene_name}++;
      }
    }
    return \%all_gene_names;
}

sub _build_gene_name_hashes {
    my ($self) = @_;
    my %gene_name_hashes;

    for my $gff_file ( @{ $self->gff_files } ) {
        Bio::AutomatedAnnotation::Exceptions::FileNotFound->throw( error => 'Cant open file: ' . $gff_file )
          unless ( -e $gff_file );
        my $gene_names_object = Bio::AutomatedAnnotation::GeneNamesFromGFF->new( gff_file => $gff_file );
        $gene_name_hashes{$gff_file} = $gene_names_object->gene_names ;
    }
    return \%gene_name_hashes;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation::GeneNameOccurances - Parse the gene names from multiple GFF files and provide a matrix of matches.

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Parse the gene names from multiple GFF files and provide a matrix of matches.
   use Bio::AutomatedAnnotation::GeneNameOccurances;

   my $obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(
     gff_files   => ['abc.gff','efg.gff','hij.gff']
   );
   my %all_gene_names = %{$obj->all_gene_names};

=head1 METHODS

=head2 all_gene_names

Returns a HashRef where the keys are all observed gene names and the values are the frequency of occurance.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
