package Alien::SeqAlignment::parasail;
use parent qw( Alien::Base );
use strict;
use warnings;




sub exe {
  my($class) = @_;
  $class->runtime_prop->{command} ;
}


sub alien_helper {
  my($class) = @_;
  return {
    parasail_aligner => sub {
      # return the CLI command for the parasail aligner
      Alien::SeqAligment::parasail->exe;
    }
  },
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::SeqAlignment::parasail

=head1 VERSION

version 0.01

=head1 SYNOPSIS

To execute the alignment using the commande line tool:

 use Alien::parasail;
 use Env qw( @PATH );

 unshift @PATH, Alien::SeqAlignment::parasail->bin_dir;
 system Alien::SeqAlignment::parasail->exe, (list of options);

=head1 DESCRIPTION

This distribution provides parsail so that it can be used by other
Perl distributions that are on CPAN.  The source code will be downloaded
from the parasail github repo, and if that fails it will use the location of a
fork but the author of this module. Contrary to other Alien modules, this one
will not test for a prior install of the parasail library, but will install 
from source into a private share location for the use by other modules. 
This strategy will avoid overwritting prior  system installs of the parasail
library, and is guaranteed to use the latest version of parasail. 
The build provides the static and shared libraries, but also the CLI aligner 
(parasail_aligner). 

=head1 NAME

Alien::SeqAlignment::parasail - find, build and install the parasail library

=head1 METHODS

=head2 exe

 Alien::SeqAlignment::parasail->exe

Returns the command name for running the CLI version of the parasail aligner.

=head1 HELPERS

%{parasail_aligner}

=head2 parasail_aligner

Returns the CLI command for the parasail aligner

=head1 SEE ALSO

=over 4

=item L<parasail|https://github.com/jeffdaily/parasail>

parasail is a SIMD C (C99) library containing implementations of the 
Smith-Waterman (local), Needleman-Wunsch (global), and various 
semi-global pairwise sequence alignment algorithms. Here, semi-global 
means insertions before the start or after the end of either the query 
or target sequence are optionally not penalized. parasail implements 
most known algorithms for vectorized pairwise sequence alignment, 
including diagonal , blocked , striped , and prefix scan. Therefore, 
parasail is a reference implementation for these algorithms in 
addition to providing an implementation of the best-performing 
algorithm(s) to date on today's most advanced CPUs.

parasail implements the above algorithms currently in three variants, 
1) returning the alignment score and ending locations, 
2) additionally returning alignment statistics (number of exact matches
, number of similarities, and alignment length), and 3) functions that 
store a traceback for later retrieval as a SAM CIGAR string. The three 
variants exist because parasail is intended to be high-performing; 
calculating additional statistics or the traceback will perform slower 
than simply calculating the alignment score. 
Select the appropriate implementation for your needs.
=back

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Christos Argyropoulos <chrisarg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
