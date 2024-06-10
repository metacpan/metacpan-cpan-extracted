package Bio::SeqAlignment::Components::Sundry::IOHelpers;
$Bio::SeqAlignment::Components::Sundry::IOHelpers::VERSION = '0.01';
use strict;
use warnings;

use Carp;
use BioX::Seq;
use BioX::Seq::Stream;
use File::Basename;
use File::Spec;

use Exporter qw(import);
our @EXPORT_OK =
  qw(read_fastx_sequences write_fastx_sequences split_fastx_sequences);

use constant FASTALENGTH => 60;

sub read_fastx_sequences
{    #read sequences from the fasta file into a @bioseq_objects
    my ($fastafile) = @_;
    my $source_path = dirname($fastafile);
    my $seqio       = BioX::Seq::Stream->new( $fastafile, fast => 1 );
    my @bioseq_objects;
    while ( my $seq = $seqio->next_seq ) {
        push @bioseq_objects, $seq;
    }
    return \@bioseq_objects;
}

sub write_fastx_sequences {
    my ( $fastafile, $bioseq_objects ) = @_;
    open my $seqio_out, ">", "$fastafile"
      or die "Error: unable to open $fastafile for writing\n";
    print {$seqio_out} $_->as_fasta(FASTALENGTH) for @{$bioseq_objects};
    close $seqio_out;
}

sub split_fastx_sequences {
    my ( $fastafiles_ref, $max_sequences_per_file ) = @_;
    my $current_file_index          = 0;
    my $current_sequence_count      = 0;
    my $current_file_sequence_count = 0;
    for my $file ( @{$fastafiles_ref} ) {
        my $seqio = BioX::Seq::Stream->new( $file, fast => 1 );
        ## change the output file name to be the part of the original file name before the extension
        my $output_file =
          $file =~ s/(.+).fasta/$1_split_$current_file_index.fasta/r;
        open my $output_seqio, '>', $output_file
          or die "Error: unable to open $output_file for writing\n";

        while ( my $seq = $seqio->next_seq ) {
            $current_sequence_count++;
            $current_file_sequence_count++;

            if ( $current_file_sequence_count > $max_sequences_per_file ) {
                $current_file_index++;
                $output_file =
                  $file =~ s/(.+).fasta/$1_split_$current_file_index.fasta/r;
                close $output_seqio;
                open $output_seqio, '>', "$output_file"
                  or die "Error: unable to open $output_file for writing\n";
                $current_file_sequence_count = 1;
            }

            print {$output_seqio} $seq->as_fasta(FASTALENGTH);
        }
        close $output_seqio;
    }

}

1;

__END__

=head1 NAME

Bio::SeqAlignment::Components::Sundry::IOHelpers - Helper functions for reading and writing (simple) sequence files

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Bio::SeqAlignment::Components::Sundry::IOHelpers qw(read_fastx_sequences write_fastx_sequences);

  my $bioseq_objects = read_fastx_sequences($fastafile);
  write_fastx_sequences($bioseq_objects, $fastafile, $outdir);

=head1 DESCRIPTION

This module provides helper functions for reading and writing (simple) sequence
files. By simple sequence files, we mean files that contain only sequence data, 
such as FASTA (and some time in the future FASTQ) files. The module uses the 
BioX::Seq module to parse sequences. This is a simple module that provides a
lightweight object-oriented interface to sequence data. It is also wickedly fast.

=head1 EXPORTS

=head2 read_fastx_sequences

  my $bioseq_objects = read_fastx_sequences($fastafile);

Read sequences from a FASTA file into an array of BioX::Seq objects. The function
returns a reference to the array of BioX::Seq objects.

=head2 split_fastx_sequences

  split_fastx_sequences($fastafiles_ref, $max_sequences_per_file);

Split a set of FASTA files into smaller files with a maximum number of sequences 
per file. The function takes a reference to an array of FASTA files and the maximum
number of sequences per file. The function writes the split files to the current
directory. The function does not return anything.

=head2 write_fastx_sequences

  write_fastx_sequences($fastafile, $bioseq_objects);

Write sequences from an array of BioX::Seq objects to a FASTA file. The function
writes the sequences to the file. Nothing too fancy, but it saves one from
writing the same boilerplate code over and over again.

=head1 SEE ALSO

=over 4

=item * L<BioX::Seq|https://metacpan.org/pod/BioX::Seq>

BioX::Seq is a simple sequence class that can be used to represent biological 
sequences. It was designed as a compromise between using simple strings and 
hashes to hold sequences and using the rather bloated objects of Bioperl. 
Benchmarking by the author of the present module, shows that its performance 
for sequence IO under the fast mode is nearly x2 the speed of the BioPerl 
SeqIO modules and 1.5x the speed of the FAST modules. The speed is rather
comparable to the Biopython SeqIO module.

=item * L<FAST|https://metacpan.org/pod/FAST>

FAST is a collection of modules that provide a simple and fast interface to
sequence data. It is designed to be lightweight and fast and it is somewhat
faster than BioPerl itself


=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg *at* cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
