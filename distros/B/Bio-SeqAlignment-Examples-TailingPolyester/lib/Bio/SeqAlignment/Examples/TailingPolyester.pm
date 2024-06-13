  use strict;
  use warnings;
  package Bio::SeqAlignment::Examples::TailingPolyester;
$Bio::SeqAlignment::Examples::TailingPolyester::VERSION = '0.01';

  1;
  
=head1 NAME

Bio::SeqAlignment::Examples::TailingPolyester - extending the Polyester RNAsequencing simulator by including polyA tails 

=head1 VERSION

version 0.01

=head1 SYNOPSIS

A collection of examples that demonstrate how to extend the polyester RNA 
sequencing tool by including polyA tails in the reference RNA being used to 
generate the simulated RNA sequencing data. The module also shows the general
B<present day> relevance of Perl for constructing bioinformatic applications
related to sequence mapping. 

=head1 DESCRIPTION

This distribution provides examples of the use of Perl, BioPerl and the Perl
Data Language to extend the polyester RNA sequencing tool by providing it with
the ability to include polyA tails in the reference RNA being used to generate
the simulated RNA sequencing data. It also shows how to use these sequences for 
RNA sequence mapping.  The main module created for the example is found under the
namespace Bio::SeqAlignment::Applications::Sequencing::Simulators::RNASeq::Polyester
and it is a command line tool that wraps over the Polyester simulator, which itself
is a R based bioconductor package. In our extension we provided polyester with the
capabilities to add a tail to the RNA sequences it simulated. To do so we also 
created a pure R command line tool for poyester and put it under the control of 
Perl. This example requires a few other modules that may be of some general  
use. Some of these modules are imported under the 
Bio::SeqAlignment::Examples::TailingPolyester namespace. Other modules were given 
their own namespace under Bio::SeqAlignment. These modules fall in three separate categories:

A Modules related to the simulation of random values from truncated distributions. 
Those are functional and will eventually find themselves under their own namespace 
once I figure which one this will be! Until then, one can load them by 
importing the relevant module under Bio::SeqAlignment::Examples::TailingPolyester
1. SimulatePDLGSL : module that uses the Gnu Scientific Library (GSL) and the Perl 
Data Language (PDL) to simulate random numbers from truncated versions of the 
distributions provided by the GSL using two role plugins: one for simulating 
random numbers from the uniform distribution, and one for computing the CDF
(Cumulative density function) of the truncated distribution and their inverse.
2. SimulateMathGSL : module that uses the Gnu Scientific Library (GSL) base Perl 
to simulate random numbers from truncated versions of the distributions in GSL 
using using two role plugins: one for simulating random numbers from the uniform 
distribution, and one for computing the CDF (Cumulative density function) of the 
truncated distribution and their inverse.
3. SimulateTruncatedRNGPDL : a role plugin that implements the inverse CDF method
for drawing random numbers from a possibly truncated version of a distribution 
using the Perl Data Language (PDL).
4. SimulateTruncatedRNG : a role plugin that implements the inverse CDF method
for drawing random numbers from a possibly truncated version of a distribution
in base Perl.
5. PDLRNG: a role plugin that draws random numbers from the uniform distribution
using the Xoshiro256+ algorithm in the Perl Data Language (PDL).
6. GSLRNG: a role plugin that draws random numbers from the uniform distribution
using the uniform (flat) distribution in the PDL::GSL module of PDL
7. PERLRNGPDL: a role plugin that draws random numbers from the uniform distribution
using the builtin rand() function in Perl and returns a ndarray with these values
8. PERLRNG: a role plugin that draws random numbers from the uniform distribution
using the builtin rand() function in Perl and returns a reference to array of said
values. 

B. Modules related to generic tasks such as reading and processing collections of 
BioX::Seq objects, tailing of sequences, documenting sequence modifications etc.
polyA processing and removal of such tails from sequencing 
data. BioX::Seq  is a lightweight framework for representing biological sequences
such as those that come from sequencing instruments. It is a simple object that
holds the sequence data, the quality data, and the name of the sequence. It is
used as a lightweight alternative to the BioPerl Bio::Seq object. It can handle
both FASTA and FASTQ files, including their compressed versions. The modules
that fall under this category are: 

1. Bio::SeqAlignment::Components::Conversions::BioXFASTX . This module handles 
the conversion of lists of BioX::Seq objects to FASTX (where X is either A or Q
indicating a FASTA or a FASTQ) file in the disk. The module is used as an example
of input/output plugins for the Bio::SeqAlignment::Components::TrimTail module.  
2. Bio::SeqAlignment::Components::Sundry::IOHelpers : a collection of modules 
that read, write and split FASTX (either FASTA or FASTQ) files. It provides 
convenience functions to read/write such files using the lightweight module
BioX::Seq::Stream.
3. Bio::SeqAlignment::Components::Sundry::Tailing : This module provides  
functions to add various tails to the 3' of biological sequences. Such 
modifications are useful for e.g. simulating polyA tails  in RNAseq, adding 
UMI (Universal Molecular Identifier) tags to sequences, etc. The function 
add_polyA is used by the 
Bio::SeqAlignment::Applications::Sequencing::Simulators::RNASeq::Polyester
module to add poly A tails in the extension of Polyester presented in the talk.
4. Bio::SeqAlignment::Components::Sundry::DocumentSequenceModifications : This
module is used to store modifications to sequences that are carried out by 
components of the simulator (or the modules that process sequences for mapping).
During the execution of the Perl code, we use hash structures to store such 
modifications (a type of in-memory log) and then write them out in YAML, JASON
or MessagePack formats. These files may be loaded at a subsequent point and used
to analyze the results of what ever sequence modification was carried out in the
source data. 


A single application script is provided in the bin directory of the distribution.
This script is called polyester.pl and is used to attach the polyA tails to the
reference sequences, before calling out the polyester R script.

In addition to this distribution contains example scripts for the use of these 
modules and comparator scripts for high performance random frequency generation 
against R and Python. PDL just shines in this area.


All modules, and application scripts were used for the talk given to the S
cience Track of the Perl & Raku conference 2024. 
https://tprc.us/tprc-2024-las/ 
https://blogs.perl.org/users/oodler_577/2024/01/perl-raku-conference-2024-to-host-a-science-track.html


=head1 scripts

This is a directory that holds various scripts in Perl and R that are used to 
generate and analyze performance data of various aspects covered in this talk.
The generated data are found in the subfolder data, while the results of these
analyses are stored as image files under 'scripts'. The following files are
found under this location: 

=head2 cutadapt_polyA_algo_timing.pl

This script benchmarks various potential approaches to trimming the polyA tail
from sequences, including various native Perl implementations of the cutadapt
algorithm, as well as PDL and C implementations of the same algorithm. It
also includes an implementation of a changepoint method in C.

=head2 cutadapt_polyA_algo_timing.py

A python script for the implementation of the cutadapt algorithm for trimming
polyA tails from sequences and a modified version developed for benchmarking. 
This script is used to compare the performance of various implementations of
the cutadapt algorithm in Perl, Python, and C.


=head2 testRNG_performance.pl

This script tests different combinations of random number generators, and 
implementations of the inverse CDF method for sampling from truncated 
distributions. It's main output is a comma separated script of timing data.

=head2 testsimsGSL.R

This script is used to test the performance of the GSL RNGs against the 
inverse CDF implemented via a procedural logic in R. It outputs a single
PNG file with the violin plots (a combination of box plots and kernel density)
of the timing data for different possible implementations of the inverse CDF
method in either R or Perl.

=head2 vioplot_Perl_R_lognormal.png

Performance comparison of Perl and R for the generation of truncated lognormal
variates. It is produced by testsimsGSL.R

=head2 testPerl.csv

This is a CSV file that contains the timing data for the Perl RNGs and the
inverse CDF method implemented in PDL. It is produced by testRNG_performance.pl

=head2 perl_timing.txt

This is a text file that contains the timing data for the various implementations
of cutadapt in native Perl, PDL and PDL/C methods. It is produced by the script
cutadapt_polyA_algo_timing.pl

=head2 python_timing.txt

This is a text file that contains the timing data for the various implementations
of cutadapt in native Python. It is produced by the script cutadapt_polyA_algo_timing.py


=head1 SEE ALSO

=over 4


=item * L<Bio::SeqAlignment|https://metacpan.org/pod/Bio::SeqAlignment>

A collection of tools and libraries for aligning biological sequences 
from within Perl. 

=item * L<cutadapt|https://metacpan.org/pod/Bio::SeqAlignment::cutadapt>

This module provides an interface to the cutadapt tool for identifying and
trimming adapters and primers from sequencing data.


=item * L<PDL|https://metacpan.org/pod/PDL>

The Perl Data Language (PDL) gives standard Perl the ability to compactly store
and speedily manipulate the large N-dimensional data arrays which are the bread
and butter of scientific computing. PDL turns Perl into a free, array-oriented,
numerical language that can be a very solid alternative to switching to Python
or R for numerical computations during complex data analysis tasks and 
pipelines. 

=item * L<polyester|https://github.com/alyssafrazee/polyester>

Polyester is an R package designed to simulate RNA sequencing experiments with
differential transcript expression.Given a set of annotated transcripts, 
Polyester will simulate the steps of an RNA-seq experiment (fragmentation, 
reverse-complementing, and sequencing) and produce files containing simulated 
RNA-seq reads. Simulated reads can be analyzed using your choice of downstream 
analysis tools.
Polyester has a built-in wrapper function to simulate a case/control experiment 
with differential transcript expression and biological replicates. Users are 
able to set the levels of differential expression at transcripts of their 
choosing. This means they know which transcripts are differentially expressed 
in the simulated dataset, so accuracy of statistical methods for differential 
expression detection can be analyzed.

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
