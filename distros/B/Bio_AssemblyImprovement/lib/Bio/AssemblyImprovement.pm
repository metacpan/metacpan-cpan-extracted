package Bio::AssemblyImprovement;
# ABSTRACT: Improve an assembly by scaffolding, contig ordering and gap closing.



use Moose;
use Bio::AssemblyImprovement::Scaffold::SSpace::PreprocessInputFiles;
use Bio::AssemblyImprovement::Scaffold::SSpace::Iterative;
use Bio::AssemblyImprovement::FillGaps::GapFiller::Iterative;
use Bio::AssemblyImprovement::Abacas::Iterative;

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::AssemblyImprovement - Improve an assembly by scaffolding, contig ordering and gap closing.

=head1 VERSION

version 1.160490

=head1 SYNOPSIS

Take in an assembly in FASTA format,reads in FASTQ format, and optionally a reference and produce a a better reference using Abacas/SSpace and GapFiller.

   # Improve the assembly without a reference
   improve_assembly -a contigs.fa -f 123_1.fastq -r 123_2.fastq 
   
   # Provide a reference
   improve_assembly -a contigs.fa -f 123_1.fastq -r 123_2.fastq  -c my_reference.fa
   
   # Gzipped input files are accepted
   improve_assembly -a contigs.fa.gz -f 123_1.fastq.gz -r 123_2.fastq.gz
   
   # Insert size defaults to 250 if not specified
   improve_assembly -a contigs.fa -f 123_1.fastq -r 123_2.fastq -i 3000
   
   # Output to a specific directory
   improve_assembly -a contigs.fa -f 123_1.fastq -r 123_2.fastq -o my_directory
   
   # This help message
   improve_assembly -h

=head1 SEE ALSO

=for :list * L<Bio::AssemblyImprovement::Scaffold::SSpace::PreprocessInputFiles>
* L<Bio::AssemblyImprovement::Scaffold::SSpace::Iterative>
* L<Bio::AssemblyImprovement::FillGaps::GapFiller::Iterative>
* L<Bio::AssemblyImprovement::Abacas::Iterative>

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
