package Bio::AutomatedAnnotation::CommandLine::ParseGenesFromGFFs;

# ABSTRACT: provide a commandline interface to pull out genes from multiple GFF files


use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Bio::AutomatedAnnotation::ParseGenesFromGFFs;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'help'        => ( is => 'rw', isa => 'Bool',     default  => 0 );

has 'amino_acids'       => ( is => 'rw', isa => 'Bool', default => 0);
has 'gff_files'         => ( is => 'rw', isa => 'ArrayRef' );
has 'search_query'      => ( is => 'rw', isa => 'Str' );
has 'search_qualifiers' => ( is => 'rw', isa => 'ArrayRef', default => sub { ['gene'] } );
has 'output_filename'   => ( is => 'rw', isa => 'Str' );

has '_error_message'    => ( is => 'rw', isa => 'Str' );

sub BUILD {
    my ($self) = @_;

    my (
        $nucleotides,       $gff_files,            $search_query, $search_qualifiers, $output_filename,        $help
    );

    GetOptionsFromArray(
        $self->args,
        'g|gene=s'          => \$search_query,
        'p|search_products' => \$search_qualifiers,
        'o|output=s'        => \$output_filename,
        'n|nucleotides'     => \$nucleotides,
        'h|help'            => \$help,
    );

    if(defined($nucleotides))
    {
      $self->amino_acids(0);
    }
    else
    {
      $self->amino_acids(1);
    }
    
    if(defined($search_query))
    {
      $self->search_query($search_query);
    }
    else
    {
      $self->_error_message("Error: You must provide a gene to search for");
    }
    
    $self->output_filename($output_filename) if(defined($output_filename));
    push(@{$self->search_qualifiers}, 'product') if(defined($search_qualifiers));

    if(@{$self->args} == 0)
    {
      $self->_error_message("Error: You need to provide at least 1 GFF file");
    }

    for my $filename (@{$self->args})
    {
      if(! -e $filename)
      {
        $self->_error_message("Error: Cant access file $filename");
        last;
      }
    }
    $self->gff_files($self->args);

}

sub run {
    my ($self) = @_;
    
    ( !$self->help ) or die $self->usage_text;
    if(defined($self->_error_message))
    {
      print $self->_error_message."\n";
      die $self->usage_text;
    }
    
    my %input_params = (gff_files         => $self->gff_files,
    search_query      => $self->search_query,
    search_qualifiers => $self->search_qualifiers,
    amino_acids       => $self->amino_acids);
    
    if(defined($self->output_filename))
    {
      $input_params{output_file} = $self->output_filename;
    }

    my $gene_finder = Bio::AutomatedAnnotation::ParseGenesFromGFFs->new(
          \%input_params       
        );

    $gene_finder->create_fasta_file;
        
    print "Samples containing gene:\t".$gene_finder->files_with_hits()."\n";
    print "Samples missing gene:\t".$gene_finder->files_without_hits()."\n";
}

sub usage_text {
    my ($self) = @_;

    return <<USAGE;
    Usage: parse_genes_from_gffs [options]
    Parse Genes from GFF files into a Fasta file

    # Get the protein sequence for the 'gryA' gene from two GFF files
    parse_genes_from_gffs -g gryA example1.gff example2.gff

    # Get the protein sequence for the 'gryA' gene from loads of GFF files
    parse_genes_from_gffs -g gryA *.gff
    
    # Expand the search to include the information in the product field
    parse_genes_from_gffs -g gryA -p example1.gff example2.gff
    
    # Output the nucleotide sequence to the FASTA file
    parse_genes_from_gffs -g gryA -n example1.gff example2.gff
    
    # Provide an output filename
    parse_genes_from_gffs -g gryA -o outputfile.fa example1.gff example2.gff

    # This help message
    parse_genes_from_gffs -h

USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation::CommandLine::ParseGenesFromGFFs - provide a commandline interface to pull out genes from multiple GFF files

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

provide a commandline interface to pull out genes from multiple GFF files

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
