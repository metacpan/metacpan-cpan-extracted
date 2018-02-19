package Bio::FastParsers;
# ABSTRACT: Classes for parsing bioinformatic programs output
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::VERSION = '0.180470';
use strict;
use warnings;

use Bio::FastParsers::Blast;
use Bio::FastParsers::Hmmer;
use Bio::FastParsers::CdHit;
use Bio::FastParsers::Uclust;

1;

__END__

=pod

=head1 NAME

Bio::FastParsers - Classes for parsing bioinformatic programs output

=head1 VERSION

version 0.180470

=head1 DESCRIPTION

This distribution includes modules for parsing the output files of a selection
of sequence comparison programs, including BLAST
L<https://blast.ncbi.nlm.nih.gov/>, HMMER L<http://hmmer.org/>, CD-HIT
L<https://github.com/weizhongli/cdhit> and UCLUST
L<http://www.drive5.com/usearch/>.

These classes are designed to add as few overhead as possible, using
constructs not far from those that would be found in home-made parsing
scripts. Moreover, their API stick closer to the behavior of each individual
software. In this respect, the approach of these parsers is very different
from Bioperl's L<Bio::SearchIO>. Hence, C<Bio::FastParsers> classes do not
need (and are not meant as a replacement for) L<BioPerl>.

C<Bio::FastParsers> modules have been used in production since 2013 but were
not yet ready for wider adoption due to their lack of documentation. This is
now nearly fixed: all modules are documented except for HMMER parsers.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Amandine BERTRAND Arnaud DI FRANCO

=over 4

=item *

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
