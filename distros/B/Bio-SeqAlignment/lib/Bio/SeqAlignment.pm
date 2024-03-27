use strict;
use warnings;
package Bio::SeqAlignment;
$Bio::SeqAlignment::VERSION = '0.02';

1;

=head1 NAME

Bio::SeqAlignment - Aligning (and pseudo aligning) biological sequences


=head1 VERSION

version 0.02

=head1 SYNOPSIS

A collection of tools and libraries for aligning biological sequences 
from within Perl. External  tools are available as shared and static 
libraries and command line tools that can be used to build Perl 
programs and distributions to carry out biological sequence alignment
and pseudo alignment. 

=head1 DESCRIPTION

The Bio::SeqAlignment distribution provides a wrapper over collection of
tools, static and dynamic libraries for (pseudo-)aligning biological.
sequences. The overarching aim is to provide a Perl ecosystem that can
be used to build components that can be integrated in pipelines and 
workflows (e.g. nextflow, snakemake, etc) for sequencing experiments, or
stand alone Perl applications that can utilize an extremely rich ecosystem
of Perl modules and libraries for bioinformatics. 

Perl had always been a very strong language for wrapping external tools,
to create a seamless experience for the programmer and the emergence of
the Alien namespace has made it even easier to handle dependencies on 
external tools and libraries. Modules that are part of the Bio::SeqAlignment
distribution may be classified as:

=over 4

=item * External Command Line Tools

=item * External Libraries

=item * Components (modules) for building Perl applications

=item * Perl Applications

=item * Examples and Tutorials

=back

=head1 EXTERNAL COMMAND LINE TOOLS

Command line tools that can perform sequence alignment and pseudo alignment
that are made available through the Alien namespace.

=over 4

=item * L<bowtie2|https://metacpan.org/pod/Alien::SeqAlignment::bowtie2>

This distribution provides bowtie2 so that it can be used by other Perl 
distributions that are on CPAN. 

=item * L<edlib|https://metacpan.org/pod/Alien::SeqAlignment::edlib>

This distribution provides edlib so that it can be used by other Perl
distributions that are on CPAN. Note that the edlib CLI is not provided
for Windows.

=item * L<hmmer3|https://metacpan.org/pod/Alien::SeqAlignment::hmmer3>

This distribution provides hmmer3 so that it can be used by other Perl
distributions that are on CPAN.

=item * L<last|https://metacpan.org/pod/Alien::SeqAlignment::last>

This distribution provides last so that it can be used by other Perl
distributions that are on CPAN.

=item * L<minimap2|https://metacpan.org/pod/Alien::SeqAlignment::minimap2>

This distribution provides minimap2 so that it can be used by other Perl
distributions that are on CPAN.

=item * L<MMseqs2|https://metacpan.org/pod/Alien::SeqAlignment::MMseqs2>

This distribution provides MMseqs2 so that it can be used by other Perl
distributions that are on CPAN.

=item * L<parasail|https://metacpan.org/pod/Alien::SeqAlignment::parasail>

This distribution provides parasail so that it can be used by other Perl
distributions that are on CPAN. 


=back

=head1 EXTERNAL LIBRARIES

Alignent suite that are available as shared and static libraries for use
with Inline/XS/FFI & SWIG. Those are made available through the Alien 
namespace.

=over 4

=item * L<edlib|https://metacpan.org/pod/Alien::SeqAlignment::edlib>

This distribution provides edlib static and shared libraries so that
they can be used by other Perl distributions that are on CPAN.

=item * L<parasail|https://metacpan.org/pod/Alien::SeqAlignment::parasail>

This distribution provides the static and dynamic libraries for parasail
so that they can be used by other Perl distributions that are on CPAN.

=back

=head1 COMPONENTS

Modules that can be used to build Perl applications for sequence alignment.
Components are modules that solve a specific problem or provide a specific
functionality in the context of sequence alignment. These modules utilize the
external tools and libraries that are part of the Bio::SeqAlignment distribution,
and may also use other Perl modules that are available on CPAN. These 
components can be used to build self-contained Perl applications, or they can
be used in non-Perl pipelines, such as Nextflow, Snakemake, etc. 

=head2 Adapter & Barcode Identification and Trimming

Modules that can assist with adapter and primer identification in sequencing
data.

=over 4

=item * L<cutadapt|https://metacpan.org/pod/Bio::SeqAlignment::cutadapt>

This module provides an interface to the cutadapt tool for identifying and
trimming adapters and primers from sequencing data.

=back

=head2 PolyA tail trimming

Modules that can assist with polyA tail trimming in RNA-seq data.

=over 4

=item * L<cutadapt|https://metacpan.org/pod/Bio::SeqAlignment::cutadapt>

This module provides an interface to the cutadapt tool which can be used
(among other things) to trim polyA tails from RNA-seq data.

=back

=head2 Read Mapping

Modules that can assist with read mapping of sequencing data.

=head2 Quantitative (RNA) Sequencing

Modules that can assist with quantification of RNA-seq data.

=head1 APPLICATIONS

Perl applications that are built using the components that wrap the external
tools and libraries that are part of the Bio::SeqAlignment distribution. These
applications can be used as standalone tools, or they can be integrated into
pipelines and workflows for sequencing experiments. The major difference 
between components and applications is that applications are "complete" 
solutions that incorporate multiple components to solve a specific problem.
On the other hand, components are "building blocks" that solve a specific
subtask in the context of sequence alignment.
While Bio::SeqAlignment does not intend to (and in fact cannot) compete with 
high-performance data pipelines, the applications listed here may provide
an alternative to complex workflows for simple problems e.g. in quantitative
or targeted sequencing, especially for field applications with portable
sequencing equipment. 

=head1 EXAMPLES AND TUTORIALS

Simple examples and tutorials that demonstrate how to use external tools
and libraries to build Perl applications for sequence alignment.

=head1 SEE ALSO

=over 2

=item * L<Alien|https://metacpan.org/pod/Alien>

Documentation on the Alien concept itself.

=item * L<Alien::Base|https://metacpan.org/pod/Alien::Base>

The base class for this Alien. The methods in that class allow you to use
the static and the dynamic edlib library in your code. 

=item * L<Alien::Build::Manual::AlienUser|https://metacpan.org/dist/Alien-Build/view/lib/Alien/Build/Manual/AlienUser.pod>

Detailed manual for users of Alien classes.

=item * L<Inline|https://metacpan.org/dist/Inline/view/lib/Inline.pod>

Write Perl Subroutines in Other Programming Languages.

=item * L<FFI|https://metacpan.org/dist/Inline/view/lib/Inline.pod>

Perl Foreign Function Interface based on libffi. This module provides a 
low-level foreign function interface to Perl. It allows the calling of 
any function for which the user can supply an address and calling signature.

=item * L<FFI::Platypus|https://metacpan.org/pod/FFI::Platypus>

Platypus is a library for creating interfaces to machine code libraries written 
in languages like C, C++, Go, Fortran, Rust, Pascal. Essentially anything that 
gets compiled into machine code. This implementation uses libffi to accomplish 
this task.

=item * L<SWIG|https://www.swig.org/>

SWIG is a software development tool that connects programs written in C and C++
with a variety of high-level programming languages.

=item * L<XS|https://perldoc.perl.org/perlxs.html>

XS is an interface description file format used to create an extension interface 
between Perl and C code (or a C library) which one wishes to use with Perl. The 
XS interface is combined with the library to create a new library which can then 
be either dynamically loaded or statically linked into perl. The XS interface 
description is written in the XS language and is the core component of the Perl 
extension interface.

=item * L<BioPerl|https://metacpan.org/pod/BioPerl>

The Bioperl Project is an international association of users & developers of open 
source Perl tools for bioinformatics, genomics and life science.

=item * L<FAST|https://metacpan.org/pod/FAST>

The Fast Analysis of Sequences Toolbox (FAST) is a set of UNIX utilities 
(for example fasgrep, fascut, fashead and fastr) that extends the UNIX toolbox 
paradigm to bioinformatic sequence records.

=item * L<NextFlow|https://www.nextflow.io/>

Nextflow enables scalable and reproducible scientific workflows using software 
containers. It allows the adaptation of pipelines written in the most common 
scripting languages. 

=item * L<Snakemake|https://snakemake.github.io>

The Snakemake workflow management system is a tool to create reproducible and 
scalable data analyses. 

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
