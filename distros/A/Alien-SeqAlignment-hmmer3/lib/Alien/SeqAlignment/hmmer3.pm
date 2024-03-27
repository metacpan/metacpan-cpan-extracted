use strict;
use warnings;

package Alien::SeqAlignment::hmmer3;
$Alien::SeqAlignment::hmmer3::VERSION = '0.03';
use parent qw( Alien::Base );
use Carp;
our $AUTOLOAD;

sub AUTOLOAD {
    my ($self) = @_;
    our $AUTOLOAD;
    $AUTOLOAD =~ s/.*::(\w+)$//;
    my $method = $1;
    unless ( exists $self->runtime_prop->{command}->{$method} ) {
        croak "Method $method not found";
    }
    else {
        no strict 'refs';
        *$AUTOLOAD = sub {
            shift->runtime_prop->{command}->{$method};
        };
    }
    use strict 'refs';
    goto &$AUTOLOAD;
}

=head1 NAME

Alien::SeqAlignment::hmmer3 - find, build and install the hmmer3 tools

=head1 VERSION

version 0.03

=head1 SYNOPSIS

To execute the hmmer3 set of tools, you can use the following code:

 use Alien::SeqAlignment::hmmer3;
 use Env qw( @PATH );
 unshift @PATH, Alien::SeqAlignment::hmmer3->bin_dir;

Now you can run the hmmer3 tools as:
 
HMMER3 SUITE

  system Alien::SeqAlignment::hmmer3->alimask       (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmalign      (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmbuild      (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmconvert    (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmemit       (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmfetch      (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmlogo       (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmpgmd       (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmpgmd_shard (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmpress      (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmsearch     (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmsim        (parameters & options);
  system Alien::SeqAlignment::hmmer3->hmmstat       (parameters & options);
  system Alien::SeqAlignment::hmmer3->jackhmmer     (parameters & options);
  system Alien::SeqAlignment::hmmer3->makehmmerdb   (parameters & options);
  system Alien::SeqAlignment::hmmer3->nhmmer        (parameters & options);
  system Alien::SeqAlignment::hmmer3->nhmmscan      (parameters & options);
  system Alien::SeqAlignment::hmmer3->phmmer        (parameters & options);

EASEL SUITE

  system Alien::SeqAlignment::hmmer3->esl_afetch     (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_alimanip   (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_alimap     (parameters & options);
  system Alien::SeqAlignment::hmmer3->asl_alimask    (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_alimerge   (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_alipid     (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_alirev     (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_alistat    (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_compalign  (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_compstruct (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_construct  (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_histplot   (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_mask       (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_mixdchlet  (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_reformat   (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_selectn    (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_seqrange   (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_seqstat    (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_sfetch     (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_shuffle    (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_ssdraw     (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_translate  (parameters & options);
  system Alien::SeqAlignment::hmmer3->esl_weight     (parameters & options);

=head1 DESCRIPTION

This distribution provides HMMER3 so that it can be used by other
Perl distributions that are on CPAN.  The source code will be downloaded
from the HMMER3 website, if the HMMER3 is not found in the system path.
The url used is : http://eddylab.org/software/hmmer/hmmer.tar.gz
The program will then be built and installed in a private share location.
The build provides the various CLI tools in the hmmer3 AND Easel suites.
Note that the Easel tools are also provided by the HMMER3 suite and this
Alien assumes that Easel has been previously installed with HMMER3 during
a prior system install. If this is not the case, attempt to use the Easel
files will terminate any Perl programs that try to use the Easel tools from
within this distribution.

=head1 METHODS : HMMER3 SUITE

=head2 alimask

  Alien::SeqAlignment::hmmer3->alimask  (parameters & options);
alimask - add column mask to a multiple sequence alignment

=head2 hmmalign

  Alien::SeqAlignment::hmmer3->hmmalign (parameters & options);
hmmalign - make multiple sequence alignment using a profile

=head2 hmmbuild

  Alien::SeqAlignment::hmmer3->hmmbuild (parameters & options);
hmmbuild - build profile from input multiple alignment

=head2 hmmconvert

  Alien::SeqAlignment::hmmer3->hmmconvert (parameters & options);
hmmconvert - convert between different profile file formats

=head2 hmmemit

  Alien::SeqAlignment::hmmer3->hmmemit (parameters & options);
hmmemit - generate (sample) sequences from a profile

=head2 hmmfetch

  Alien::SeqAlignment::hmmer3->hmmfetch (parameters & options);
hmmfetch - retrieve profile(s) from a profile file

=head2 hmmlogo

  Alien::SeqAlignment::hmmer3->hmmlogo (parameters & options);
hmmlogo - produce a conservation logo graphic from a profile

=head2 hmmpgmd

  Alien::SeqAlignment::hmmer3->hmmpgmd (parameters & options);
hmmpgmd - search daemon for the hmmer.org website

=head2 hmmpgmd_shard

  Alien::SeqAlignment::hmmer3->hmmpgmd_shard (parameters & options);
hmmpgmd_shard - sharded search daemon for the hmmer.org website

=head2 hmmscan

  Alien::SeqAlignment::hmmer3->hmmscan (parameters & options);
hmmscan - search sequence(s) against a profile database

=head2 hmmsearch

  Alien::SeqAlignment::hmmer3->hmmsearch (parameters & options);  
hmmsearch - search profile against sequence database

=head2 hmmpress

  Alien::SeqAlignment::hmmer3->hmmpress (parameters & options);
hmmpress - prepare profile database for hmmscan

=head2 phmmer

  Alien::SeqAlignment::hmmer3->phmmer (parameters & options);
phmmer - search single sequence against sequence database

=head2 jackhmmer

  Alien::SeqAlignment::hmmer3->jackhmmer (parameters & options);
jackhmmer - iteratively search single sequence against database

=head2 nhmmer

  Alien::SeqAlignment::hmmer3->nhmmer (parameters & options);
nhmmer - search DNA query against DNA sequence database

=head2 nhmmscan

  Alien::SeqAlignment::hmmer3->nhmmscan (parameters & options);
nhmmscan - search DNA sequence against a DNA profile database

=head2 hmmstat

  Alien::SeqAlignment::hmmer3->hmmstat (parameters & options);
hmmstat - show summary statistics for a profile file

=head2 makehmmerdb

  Alien::SeqAlignment::hmmer3->makehmmerdb (parameters & options);
makehmmerdb - prepare an nhmmer binary database

=head2 hmmsim

  Alien::SeqAlignment::hmmer3->hmmsim (parameters & options);
hmmsim - collect score distributions on random sequences

=head1 METHODS : EASEL SUITE

Note that the names of the methods are the same as the functions in the
CLI of the EASEL suite, but with the "-" replaced by "_", e.g. esl-afetch
becomes esl_afetch.

=head2 esl_afetch

  Alien::SeqAlignment::hmmer3->esl_afetch (parameters & options);
esl_afetch - retrieve alignments from a multi-MSA database

=head2 esl_alimanip

  Alien::SeqAlignment::hmmer3->esl_alimanip (parameters & options);
esl_alimanip - manipulate a multiple sequence alignment

=head2 esl_alimap

  Alien::SeqAlignment::hmmer3->esl_alimap (parameters & options);
esl_alimap - map two alignments to each other

=head2 esl_alimask

  Alien::SeqAlignment::hmmer3->esl_alimask (parameters & options);

=head2 esl_alimerge
  
    Alien::SeqAlignment::hmmer3->esl_alimerge (parameters & options);
esl_alimerge - merge alignments based on their reference (RF) annotation

=head2 esl_alipid

  Alien::SeqAlignment::hmmer3->esl_alipid (parameters & options);
esl_alipid - calculate pairwise percent identities for all sequence

=head2 esl_alirev

  Alien::SeqAlignment::hmmer3->esl_alirev (parameters & options);
esl_alirev - reverse complement a multiple alignment

=head2 esl_alistat

  Alien::SeqAlignment::hmmer3->esl_alistat (parameters & options);
esl_alistat - summarize a multiple sequence alignment file

=head2 esl_compalign

  Alien::SeqAlignment::hmmer3->esl_compalign (parameters & options);
esl_compalign - compare two multiple sequence alignments

=head2 esl_compstruct

  Alien::SeqAlignment::hmmer3->esl_compstruct (parameters & options);
esl_compstruct - calculate accuracy of RNA secondary structure predictions

=head2 esl_construct

  Alien::SeqAlignment::hmmer3->esl_construct (parameters & options);
esl_construct - describe or create a consensus secondary structure

=head2 esl_histplot

  Alien::SeqAlignment::hmmer3->esl_histplot (parameters & options);
esl_histplot - collate data histogram, output xmgrace datafile

=head2 esl_mask

  Alien::SeqAlignment::hmmer3->esl_mask (parameters & options);
esl_mask - mask sequence residues with Xs (or other characters)

=head2 esl_mixdchlet

  Alien::SeqAlignment::hmmer3->esl_mixdchlet (parameters & options);
esl_mixdchlet - fitting mixture Dirichlets to count data

=head2 esl_reformat

  Alien::SeqAlignment::hmmer3->esl_reformat (parameters & options);
esl_reformat - convert sequence file formats

=head2 esl_selectn

  Alien::SeqAlignment::hmmer3->esl_selectn (parameters & options);
esl_selectn - select random subset of lines from file

=head2 esl_seqrange

  Alien::SeqAlignment::hmmer3->esl_seqrange (parameters & options);
esl_seqrange - determine a range of sequences for one of many parallel

=head2 esl_seqstat
  
    Alien::SeqAlignment::hmmer3->esl_seqstat (parameters & options);
esl_seqstat - summarize contents of a sequence file

=head2 esl_sfetch

  Alien::SeqAlignment::hmmer3->esl_sfetch (parameters & options);
esl_sfetch - retrieve (sub-)sequences from a sequence file

=head2 esl_shuffle

  Alien::SeqAlignment::hmmer3->esl_shuffle (parameters & options);
esl_shuffle - shuffling sequences or generating random ones

=head2 esl_ssdraw

  Alien::SeqAlignment::hmmer3->esl_ssdraw (parameters & options);
esl_ssdraw - create postscript secondary structure diagrams

=head2 esl_translate

  Alien::SeqAlignment::hmmer3->esl_translate (parameters & options);
esl_translate - translate DNA sequence in six frames into individual

=head2 esl_weight

  Alien::SeqAlignment::hmmer3->esl_weight (parameters & options);
esl_weight - calculate sequence weights in MSA(s)

=head1 SEE ALSO

=over 4

=item * L<HMMER|http://hmmer.org/>

HMMER: biosequence analysis using profile hidden Markov models

HMMER is used for searching sequence databases for sequence homologs, and for
making sequence alignments. It implements methods using probabilistic models
called profile hidden Markov models (profile HMMs).

HMMER is often used together with a profile database, such as Pfam or many of
the databases that participate in Interpro. But HMMER can also work with query
sequences, not just profiles, just like BLAST. For example, you can search a
protein query sequence against a database with phmmer, or do an iterative
search with jackhmmer.

HMMER is designed to detect remote homologs as sensitively as possible,
relying on the strength of its underlying probability models. In the past,
this strength came at significant computational expense, but as of the new
HMMER3 project, HMMER is now essentially as fast as BLAST.

HMMER can be downloaded and installed as a command line tool on your own
hardware, and now it is also more widely accessible to the scientific community
via new search servers at the European Bioinformatics Institute. 


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
