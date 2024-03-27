  use strict;
  use warnings;
  package Alien::SeqAlignment::bowtie2;
$Alien::SeqAlignment::bowtie2::VERSION = '0.03';
use parent qw( Alien::Base );
=head1 NAME

Alien::SeqAlignment::bowtie2 - find, build and install the bowtie2 tools

=head1 VERSION

version 0.03

=head1 SYNOPSIS

To execute the hmmer3 set of tools, you can use the following code:

 use Alien::SeqAlignment::bowtie2;
 use Env qw( @PATH );
 unshift @PATH, Alien::SeqAlignment::bowtie2->bin_dir;
 
 Alien::SeqAlignment::bowtie2->bowtie2_build      (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_inspect    (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2            (list of arguments)
 
 Alien::SeqAlignment::bowtie2->bowtie2_build_s    (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_inspect_s  (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_align_s    (list of arguments)

 Alien::SeqAlignment::bowtie2->bowtie2_build_l    (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_inspect_l  (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_align_l    (list of arguments)

=head1 DESCRIPTION

This distribution provides bowtie2 so that it can be used by other
Perl distributions that are on CPAN.  The source code will be downloaded
from the github repository and installed in a private location if it is 
not already installed in your system. The bowtie2, bowtie2-build and 
bowtie2-inspect executables are actually wrapper scripts that call binary 
programs as appropriate. The wrappers shield users from having to distinguish 
between "small" (<4GB) and "large" (>4GB)  index formats. 
Also, the bowtie2 (Perl!) wrapper provides some key functionality, 
like the ability to handle compressed inputs, and the functionality 
for --un, --al and related options. While the creators of bowtie2 recommend 
that one always runs the bowtie2 wrappers and not the binaries, application
builders may want to call these functions directly when implementing custom
workflows. Hence, this distributions exposes all functions provided in bowtie2

=head1 METHODS

=head2 bowtie2

 Alien::SeqAlignment::bowtie2->bowtie2            (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_align_s    (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_align_l    (list of arguments)
  
Returns the command name for running the CLI version of the bowtie2 aligner.
The method effectively runs the perl script bowtie2.pl that is distributed
with bowtie2. The methods Alien::SeqAlignment::bowtie2->bowtie2_align_s and
Alien::SeqAlignment::bowtie2->bowtie2_align_l return the binary executables
that align against small and large index formats respectively.


=cut

sub bowtie2 {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2} ;
}

sub bowtie2_align_l {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2_align_l} ;
};

sub bowtie2_align_s {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2_align_s} ;
}


=head2 bowtie2_build

 Alien::SeqAlignment::bowtie2->bowtie2_build     (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_build_s   (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_build_l   (list of arguments)
  
Returns the command name for the python application bowtie2-build,that builds 
the database of the reference sequences. bowtie2-build can generate either 
small or large indexes. The wrapper will decide which based on the length of 
the input genome. If the reference does not exceed 4 billion characters but 
a large index is preferred, the user can specify --large-index to force 
bowtie2-build to build a large index instead.
The methods Alien::SeqAlignment::bowtie2->bowtie2_build_s and 
Alien::SeqAlignment::bowtie2->bowtie2_build_l return the names of the *binary*
executables that bowtie2-build wraps over.


=cut

sub bowtie2_build {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2_build} ;
}

sub bowtie2_build_s {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2_build_s} ;
}

sub bowtie2_build_l {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2_build_l} ;
}


=head2 bowtie2_inspect

 Alien::SeqAlignment::bowtie2->bowtie2_inspect    (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_inspect_s  (list of arguments)
 Alien::SeqAlignment::bowtie2->bowtie2_inspect_l  (list of arguments)
 
bowtie2-inspect extracts information from a Bowtie index about what kind of 
index it is and what reference sequences were used to build it. This method 
provides an interface to the python wrapper function over the binary 
executables Alien::SeqAlignment::bowtie2->bowtie2_inspect_s and
Alien::SeqAlignment::bowtie2->bowtie2_inspect_l that inspect short and long
format indices. 

=cut

sub bowtie2_inspect {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2_inspect} ;
}

sub bowtie2_inspect_s {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2_inspect_s} ;
}

sub bowtie2_inspect_l {
    my ($class) = @_;
  $class->runtime_prop->{command}->{bowtie2_inspect_l} ;
}


=head1 SEE ALSO

=over 4

=item * L<bowtie2|https://bowtie-bio.sourceforge.net/index.shtml>

Bowtie is an ultrafast, memory-efficient short read aligner. It aligns short 
DNA sequences (reads) to the human genome at a rate of over 25 million 
35-bp reads per hour. Bowtie indexes the genome with a Burrows-Wheeler index 
to keep its memory footprint small: typically about 2.2 GB for the human 
genome (2.9 GB for paired-end). 

=item * L<Alien>

Documentation on the Alien concept itself.

=item * L<Alien::Base|https://metacpan.org/pod/Alien::Base>

The base class for this Alien. The methods in that class allow you to use
the static and the dynamic edlib library in your code. 

=item * L<Alien::Build::Manual::AlienUser|https://metacpan.org/dist/Alien-Build/view/lib/Alien/Build/Manual/AlienUser.pod>

Detailed manual for users of Alien classes.

=item * L<Bio::SeqAlignment|https://metacpan.org/pod/Bio::SeqAlignment>

A collection of tools and libraries for aligning biological sequences 
from within Perl. 

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
  1;
