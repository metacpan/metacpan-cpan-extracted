package Bio::Roary::CombinedProteome;
$Bio::Roary::CombinedProteome::VERSION = '3.11.0';
# ABSTRACT: Take in multiple FASTA sequences containing proteomes and concat them together and output a FASTA file, filtering out more than 5% X's


use Moose;
use Bio::Roary::Exceptions;

has 'proteome_files'                 => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'output_filename'                => ( is => 'ro', isa => 'Str',      default  => 'combined_output.fa' );

sub BUILD {
    my ($self) = @_;

    for my $filename ( @{ $self->proteome_files } ) {
        Bio::Roary::Exceptions::FileNotFound->throw( error => 'Cant open file: ' . $filename )
          unless ( -e $filename );
    }
}



sub create_combined_proteome_file {
    my ($self) = @_;
    
    unlink($self->output_filename);
    for my $filename (@{$self->proteome_files })
    {
       system(join(' ', ("cat", $filename, ">>", $self->output_filename)));
    }

    1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Roary::CombinedProteome - Take in multiple FASTA sequences containing proteomes and concat them together and output a FASTA file, filtering out more than 5% X's

=head1 VERSION

version 3.11.0

=head1 SYNOPSIS

Take in multiple FASTA sequences containing proteomes and concat them together and output a FASTA file, filtering out more than 5% X's
   use Bio::Roary::CombinedProteome;

   my $obj = Bio::Roary::CombinedProteome->new(
     proteome_files   => ['abc.fa','efg.fa'],
     output_filename   => 'example_output.fa',
     maximum_percentage_of_unknowns => 5.0,
   );
   $obj->create_combined_proteome_file;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
