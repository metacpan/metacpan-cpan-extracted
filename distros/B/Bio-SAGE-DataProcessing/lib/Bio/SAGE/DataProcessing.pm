# *%) $Id: DataProcessing.pm,v 1.26 2004/10/15 22:30:46 scottz Exp $
#
# Copyright (c) 2004 Scott Zuyderduyn <scottz@bccrc.ca>.
# All rights reserved. This program is free software; you
# can redistribute it and/or modify it under the same
# terms as Perl itself.

package Bio::SAGE::DataProcessing;

=pod

=head1 NAME

Bio::SAGE::DataProcessing - Processes raw serial analysis of gene expression (SAGE) data.

=head1 SYNOPSIS

  use Bio::SAGE::DataProcessing;
  $sage = Bio::SAGE::DataProcessing->new();

  # open sequence and quality files
  open( READS, "library.fasta" );
  open( QUAL, "library.qual.fasta" );

  # collect ditags and statistics from reads
  $sage->process_library( *READS, *QUAL );

  # close files
  close( READS );
  close( QUAL );

  # output tags in descending order of expression
  my %tags = %{$sage->get_tagcounts()};
  open( TAGS, ">library.tags" );
  map { print TAGS join( "\t", $_, $tags{$_} ) . "\n" } sort { $tags{$b} <=> $tags{$a} } keys %tags;
  close( TAGS );

  # tag AAACCGGGTT matches two different genes
  # so 15th base pair may help resolve this
  $sage->print_extra_base_calculation( $sage->get_extract_base_calculation( "AAACCGGGTT" ) );

=head1 DESCRIPTION

This module provides several tools for processing and
analyzing serial analysis of gene expression (SAGE)
libraries.

=head1 README

B<BACKGROUND>

Serial analysis of gene expression (SAGE) is a molecular
technique for generating a near-global snapshot of a
cell population’s transcriptome.  Briefly, the technique
extracts short sequences at defined positions of
transcribed mRNA.  These short sequences are then paired
to form ditags.  The ditags are concatamerized to form
long sequences that are then cloned.  The cloned DNA is
then sequenced.  Bioinformatic techniques are then
employed to determine the original short tag sequences,
and to derive their progenitor mRNA.  The number of times
a particular tag is observed can be used to quantitate
the amount of a particular transcript.  The original
technique was described by Velculescu et al. (1995) and
utilized an ~14bp sequence tag.  A modified protocol
was introduced by Saha et al. (2002) that produced ~21bp
tags.

B<PURPOSE>

This module facilitates the processing of SAGE data.
Specifically:

  1. extracting ditags from raw sequence reads.
  2. extracting tags from ditags, with the option to
     exclude tags if the Phred scores (described by
     Ewing and Green, 1998a and Ewing et al., 1998b)
     do not meet a minimum cutoff value.
  3. calculating descriptive values
  4. statistical analysis to determine, where possible,
     additional nucleotides to extend the length of the
     SAGE tag (thus facilitating more accurate tag to
     gene mapping).

Both regular SAGE (14mer tag) and LongSAGE (21mer tag)
are supported by this module.  Future protocols should
be configurable with this module.

B<REFERENCES>

  Velculescu V, Zhang L, Vogelstein B, Kinzler KW. (1995)
  Serial analysis of gene expression. Science. 270:484-487.

  Saha S, Sparks AB, Rago C, Akmaev V, Wang CJ, Vogelstein B,
  Kinzler KW, Velculescu V. (2002) Using the transcriptome
  to annotate the genome. Nat. Biotechnol. 20:508-512.

  Ewing B, Hillier L, Wendl MC, Green P. (1998a) Base-calling
  of automated sequencer traces using phred. I. Accuracy
  assessment. Genome Res. 8:175-185.

  Ewing B, Green P. (1998b) Base-calling of automated
  sequencer traces using phred. II. Error probabilities.
  Genome Res. 8:186-194.

=head1 INSTALLATION

Follow the usual steps for installing any Perl module:

  perl Makefile.PL
  make test
  make install

=head1 PREREQUISITES

None (this module used to require the C<Statistics::Distributions> package).

=head1 CHANGES

  1.20 2004.10.15 - Minor spelling errors and misuse of terminology fixed in docs.
                  - Module now allows FASTA files with a blank line folling the
                    header (denoting an attempted read with no sequence), but prints
                    a warning to STDERR that this has happened. Module died previously.
  1.11 2004.06.20 - Added flag in constructor to keep duplicate ditags.
  1.10 2004.06.02 - Wrote new documentation and modified several methods to use the read-by-read
                    processing approach (see line below).
                  - Revamped the module to conserve memory. Reads are now processed one at a time
                    and then discarded. The memory requirements in the previous versions were
                    prohibitive to those with regular desktop machines.
                  - The Bio::SAGE::DataProcessing::Filter package can be subclassed to create
                    custom filters at the ditag and tag processing steps (previous versions only
                    allowed one approach to ditag/tag filtering).
  1.01 2004.05.27 - Fixed bug where extract_tag_counts didn't work with quality cutoff defined.
                  - extract_tags was not applying the get_quality_cutoff value (was returning all data)
                  - Duplicate ditags are now removed by default.
  1.00 2004.05.23 - Initial release.

=cut

use strict;
use diagnostics;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $PROTOCOL_SAGE $PROTOCOL_LONGSAGE $DEBUG $ENZYME_NLAIII $ENZYME_SAU3A $DEFAULT_DITAG_FILTER $DEFAULT_TAG_FILTER );

require Exporter;
require AutoLoader;

@ISA = qw( Exporter AutoLoader );
@EXPORT = qw();
$VERSION = "1.11";

#use Statistics::Distributions;
use Bio::SAGE::DataProcessing::Filter;
use Bio::SAGE::DataProcessing::AveragePhredFilter;
use Bio::SAGE::DataProcessing::MinimumPhredFilter;

my $PACKAGE = "Bio::SAGE::DataProcessing";

=pod

=head1 VARIABLES

B<Globals>

=over 2

I<$PROTOCOL_SAGE>

  Hashref containing default protocol parameters for the
  regular/original SAGE protocol (see set_protocol
  documentation for more information).

I<$PROTOCOL_LONGSAGE>

  Hashref containing default protocol parameters for the
  LongSAGE protocol (see set_protocol documentation
  for more information).

I<$ENZYME_NLAIII> = 'CATG'

  Constant denoting the recognition sequence for NlaIII.

I<$ENZYME_SAU3A> = 'GATC'

  Constant denoting the recognition sequence for Sau3a.

I<$DEFAULT_TAG_FILTER>

  A default tag filter used when none is specified.
  This filter rejects tags that contain any base pair
  with a Phred quality score < 15 or an average
  Phred quality score over all bases < 30.

I<$DEFAULT_DITAG_FILTER>

  A default ditag filter used when none is specified.
  This filter rejects ditags that contain any base pair
  with a Phred quality score < 20.

=back

B<Settings>

=over 2

I<$DEBUG = 0>

  Prints debugging output if value if >= 1.

=back

=cut

my @ignoreTags = ( 'TCCCTATTAA', 'TCCCCGTACA' ); # linker derived sequences
my @ignoreLongTags = ( 'TCGGACGTACATCGTTA', 'TCGGATATTAAGCCTAG' ); # linker derived sequences

my %params_sage = ( 'MINIMUM_DITAG_LENGTH' => 29,
                    'MAXIMUM_DITAG_LENGTH' => 32,
                    'TAG_LENGTH'           => 10,
                    'IGNORE_TAGS'          => \@ignoreTags );
my %params_longsage = ( 'MINIMUM_DITAG_LENGTH' => 40,
                        'MAXIMUM_DITAG_LENGTH' => 46,
                        'TAG_LENGTH'           => 17,
                        'IGNORE_TAGS'          => \@ignoreLongTags );

$PROTOCOL_SAGE = \%params_sage;         # regular SAGE (14-mer tags)
$PROTOCOL_LONGSAGE = \%params_longsage; # LongSAGE (21-mer tags)

$ENZYME_NLAIII = "CATG";
$ENZYME_SAU3A  = "GATC";

$DEFAULT_TAG_FILTER = Bio::SAGE::DataProcessing::AveragePhredFilter->new( 30, 15 );
$DEFAULT_DITAG_FILTER = Bio::SAGE::DataProcessing::MinimumPhredFilter->new( 20 );

$DEBUG = 0; # set this flag to non-zero to enable debugging messages

=pod

=head1 CLASS METHODS

=cut

#######################################################
sub new {
#######################################################
=pod

=head2 new <$enzyme>, <\%protocol>, <$bKeepDuplicates>

Constructor for a new Bio::SAGE::DataProcessing object.

B<Arguments>

I<$enzyme> (optional)

  The anchoring enzyme recognition site. This is
  typically NlaIII (CATG) or Sau3a (GATC). The
  default is the recognition sequence "CATG" (NlaIII).

I<\%protocol> (optional)

  A hashref containing specifics of the protocol. Two
  pre-made parameter sets are available: $PROTOCOL_SAGE
  (regular SAGE) and $PROTOCOL_LONGSAGE (LongSAGE).

  The required hash keys:

    MINIMUM_DITAG_LENGTH | The shortest length a valid
                           ditag can be (the length
                           should include the anchoring
                           enzyme site sequences).
    MAXIMUM_DITAG_LENGTH | The longest length a valid
                           ditag can be (the length
                           should include the anchoring
                           enzyme site sequences).
    TAG_LENGTH           | The expected tag length (the
                           length should NOT include the
                           anchoring enzyme site sequence).
    IGNORE_TAGS          | An arrayref listing tag
                           sequences that should be
                           ignored during tag extraction
                           (i.e. linker-derived sequences).

  The parameters for the default configurations are:

                           +----------------+--------------------+
                           | $PROTOCOL_SAGE | $PROTOCOL_LONGSAGE |
    +----------------------+----------------+--------------------+
    | MINIMUM_DITAG_LENGTH |       29       |         40         |
    +----------------------+----------------+--------------------+
    | MAXIMUM_DITAG_LENGTH |       32       |         46         |
    +----------------------+----------------+--------------------+
    | TAG_LENGTH           |       10       |         17         |
    +----------------------+----------------+--------------------+
    | IGNORE_TAGS          |   TCCCTATTAA   | TCGGACGTACATCGTTA  |
    |                      |   TCCCCGTACA   | TCGGATATTAAGCCTAG  |
    +----------------------+----------------+--------------------+

  Once the Bio::SAGE::DataProcessing object has been instantiated,
  the enzyme and protocol CANNOT be altered.

I<$bKeepDuplicates> (optional)

  If this argument is TRUE (non-zero) then ditags with
  identical sequence will be kept.  The default behavior is
  to discard these ditags as they likely represent
  preferential PCR amplification.

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new( $Bio::SAGE::DataProcessing::ENZYME_NLAIII,
                                             $Bio::SAGE::DataProcessing::PROTOCOL_LONGSAGE );

  # alternatively:
  my $sage = Bio::SAGE::DataProcessing->new( "CATG", { 'MINIMUM_DITAG_LENGTH' => 31,
                                                       'MAXIMUM_DITAG_LENGTH' => 34,
                                                       'TAG_LENGTH'           => 11,
                                                       'IGNORE_TAGS'          => \( 'TCCCTATTAA', 'TCCCCGTACA' ) } );

=cut

    my $this = shift;
    my $enzyme = shift || "CATG";
    my $protocol = shift || $PROTOCOL_SAGE;
    my $bKeepDupes = shift || 0;
    my $class = ref( $this ) || $this;
    my $self = {};
    bless( $self, $class );

    # set instance variables
    $self->{'enzyme'} = $enzyme;
    $self->{'protocol'} = $protocol;
    $self->{'keep_duplicates'} = $bKeepDupes;
#    $self->set_protocol( $protocol );

    $self->{'ditag_filter'} = $DEFAULT_DITAG_FILTER;
    $self->{'tag_filter'} = $DEFAULT_TAG_FILTER;

    return $self;

}

=pod

=head1 INSTANCE METHODS

=cut

#######################################################
sub set_ditag_filter {
#######################################################
=pod

=head2 set_ditag_filter $filterObject

Sets a new filter object (a concrete subclass of
Bio::SAGE::DataProcessing::Filter) that is applied
to ditags as they're extracted from sequence reads.

The default filter uses a Bio::SAGE::DataProcessing::MinimumPhredFilter
instance that is set to reject any ditags that do not
have at least Phred 20 (p<=0.01) for all nucleotides.

B<Arguments>

I<$filterObject>

  An object ref to a concrete subclass of
  Bio::SAGE::DataProcessing::Filter.

=cut

    my $self = shift;
    $self->{'ditag_filter'} = shift || die( $PACKAGE . "::set_ditag_filter no filter specified." );

}

#######################################################
sub set_tag_filter {
#######################################################
=pod

=head2 set_tag_filter $filterObject

Sets a new filter object (a concrete subclass of
Bio::SAGE::DataProcessing::Filter) that is applied
to tags as they're extracted from ditags.

The default filter uses a Bio::SAGE::DataProcessing::AveragePhredFilter
instance that is set to reject any tags that do not
have an average Phred 30 score (p<=0.001) over all
nucleotides and at least Phred 15 (p<=0.0316) at
each nucleotide.

B<Arguments>

I<$filterObject>

  An object ref to a concrete subclass of
  Bio::SAGE::DataProcessing::Filter.

=cut

    my $self = shift;
    $self->{'tag_filter'} = shift || die( $PACKAGE . "::set_tag_filter no filter specified." );

}

#######################################################
sub get_enzyme {
#######################################################
=pod

=head2 get_enzyme

Gets the current anchoring enzyme recognition site.

B<Arguments>

  None.

B<Returns>

  The current anchoring enzyme recognition site. By
  default, this will be 'CATG', the NlaIII recognition
  site.

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new();
  print "ENZYME_SITE: " . $sage->get_enzyme() . "\n";

=cut

    my $this = shift;

    return $this->{'enzyme'};

}

#######################################################
sub get_protocol {
#######################################################
=pod

=head2 get_protocol

Gets a copy (in other words, modifying the
returned hash does not affect the object's settings)
of the hash describing the protocol for this
instance.

B<Arguments>

  None.

B<Returns>

  A hashref of the current protocol settings.  See the
  documentation for new (constructor) for more details
  on the contents of this hash.

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new();
  print "Default protocol:\n";
  my %protocol = %{$sage->get_protocol()};
  map { print $_ . "=" . $protocol{$_} . "\n" } keys %protocol;

=cut

  my $this = shift;
  my %protocol = %{$this->{'protocol'}};

  my %copy;
  foreach my $key ( keys %protocol ) {
    my $val = $protocol{$key};
    if( $key eq 'IGNORE_TAGS' ) {
      my @arr = @$val;
      $val = \@arr;
    }
    $copy{$key} = $val;
  }

  return \%copy;

}

#######################################################
sub process_library {
#######################################################
=pod

=head2 process_library $sequence_handle, <$scores_handle>

Processes reads from a Perl handle to FASTA format
sequence data.  Phred scores in matching FASTA format
can be read concurrently.

An example of FASTA format sequence:

  >SEQUENCE0001
  ACAGATAGACAGAGATATAGAGACATATTTAGAGACAAATCGCGCAGGCGCGCGACATA
  TGACTAGTTTATATCATCAGTATTAGCGATTATGACTATTATATATTACTGATTGATCT
  ATAGCGCGATTATATCTATCTATGCATTCGATCATGCTATTATCGTATACTACTGCTAG
  AGAGGACGACGCAGGCAGCGATTATATCTATTTATA
  >SEQUENCE0002
  CGCGACGCATGTCAGTAGCTAGCTGCGCCCGAATATATATCGTCATACGGATTCGTAGC
  CCCCCGCGGAGTCTGATTATATCTGATT

An example of FASTA format quality data:

  >SEQUENCE0001
  11 17 18 16 19 17 19 19 16 19 19 16 11 10 9 15 10 12 24 24 35 29 29 39 40 40 40 40 37 37 46 46 40 40 40 40 56 56 56 56 35 35 35 35 35 35 56 40 40 46 40 40 39 39 35 39 56 56 51 51
  51 51 51 56 35 35 35 35 35 35 40 40 51 45 51 51 39 39 39 39 39 39 40 40 40 40 40 40 56 56 56 56 56 46 46 40 39 39 39 45 45 45 56 56 56 56 56 56 56 56 40 39 39 39 39 35 39 39 39 39
  45 56 45 45 45 45 51 35 39 39 39 39 39 40 40 40 40 40 51 56 56 40 40 40 40 40 43 56 56 56 43 35 35 35 35 35 43 45 45 45 45 45 45 51 51 51 51 51 51 56 56 56 56 56 56 51 51 51 56 56
  7 7 9 9 11 10 13 11 10 8 10 10 8 8 8 10 10
  >SEQUENCE0002
  12 15 17 17 19 15 15 15 13 19 17 17 12 16 11 19 13 24 24 35 35 35 37 37 39 56 56 56 56 56 51 39 32 29 29 29 29 32 56 56 56 35 35 35 35 35 35 56 56 56 56 56 56 56 56 56 56 56 56 40
  40 40 46 46 40 51 40 40 40 40 40 40 51 39 39 35 35 35 35 40 40 51 45 45 45 45 51 51 56 56 56 56 56 45 45 45 45 51 51 45 45 45 40 40 40 40 40 40 40 40 40 40 56 56 56 56 56 56 51 51
  15 13 19 17 17 12 16 11 19 13

B<Arguments>

I<$sequence_handle>

  A Perl handle to sequence data in FASTA format.

I<$scores_handle> (optional)

  A Perl handle to Phred scores in FASTA format. The order
  of entries must match the $sequence_handle data.  NOTE:
  many implementations of Bio::SAGE::DataProcessing::Filter
  require the scores to carry out their function.  In the
  default implementations, no filtering is done when scores
  are not defined.

B<Returns>

  The number of sequences read.

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new();
  open( SEQDATA, "sequences.fasta" );
  my $nReads = $sage->process_library( *SEQDATA );
  print "NUMBER_READS: $nReads\n";

=cut

    my $this = shift || die( $PACKAGE . "::process_library can't be called statically." );
    my $fh1  = shift || die( $PACKAGE . "::process_library no sequence data handle provided." );
    my $fh2  = shift || undef;

    my $nRead = 0;

    my $currid = '';
    my $currseq = '';

    my $currscoreid = '';

    while( my $line = <$fh1> ) {
        chomp( $line ); $line =~ s/\r//g;
        if( $line =~ /^>(.*?)$/ ) {
            my $thisid = $1;
            if( $currid ne '' ) {

                # do we have scores too?

                my $scores = '';
                if( defined( $fh2 ) ) {
                    while( my $line2 = <$fh2> ) {
                        chomp( $line2 ); $line2 =~ s/\r//g;
                        if( $line2 =~ /^>(.*?)$/ ) {
                            my $thisscoreid = $1;
                            if( $currscoreid eq '' ) { $currscoreid = $thisscoreid; next; }
                            if( $currid ne $currscoreid ) { die( $PACKAGE . "::process_library sequence and score data don't match." ); }
                            $currscoreid = $thisscoreid;
                            last;
                        }
                        if( $scores ne '' ) { $scores .= ' '; }
                        $scores .= $line2;
                    }
                }

                if( $scores eq '' ) { $scores = undef; }
                if( $this->process_read( $currseq, $scores ) == 0 ) {
                    print STDERR "Non-fatal error on read >".$currid." ...\n";
                    print STDERR "  Sequence: $currseq\n";
                    print STDERR "  Scores  : " . ( defined($scores) ? $scores : '' ) . "\n";
                    print STDERR "...continuing.\n";
                }
                $currseq = '';
                $nRead++;

            }
            $currid = $thisid;
            next;
        }
        $currseq .= $line;

    }

    if( $currid ne '' ) {

        # do we have scores too?

        my $scores = '';
        if( defined( $fh2 ) ) {
            while( my $line2 = <$fh2> ) {
                chomp( $line2 ); $line2 =~ s/\r//g;
                if( $line2 =~ /^>(.*?)$/ ) {
                    my $thisscoreid = $1;
                    if( $currscoreid eq '' ) { $currscoreid = $thisscoreid; next; }
                    if( $currid ne $currscoreid ) { die( $PACKAGE . "::process_library sequence and score data don't match." ); }
                    $currscoreid = $thisscoreid;
                    last;
                }
                if( $scores ne '' ) { $scores .= ' '; }
                $scores .= $line2;
            }
        }

        if( $scores eq '' ) { $scores = undef; }
        if( $this->process_read( $currseq, $scores ) == 0 ) {
            print STDERR "Error: " . $currid . "\n";
            print STDERR $currseq . "\n";
            print STDERR $scores . "\n";
        }
        $currseq = '';
        $currid = '';
        $nRead++;

    }

    return $nRead;

}

#######################################################
sub process_read {
#######################################################
=pod

=head2 process_read $sequence, <$scores>

Extracts and filters ditags from the given sequence read
(and optionally supplied Phred scores).  The default ditag
filter (or a filter supplied to set_ditag_filter) is
applied during this procedure.  The resulting ditags are
added to the list of currently processed ditags collected
from previous calls to this method.

Ditags with identical sequence (duplicate ditags) are
considered the result of PCR artifacts and only the
ditag with the highest "score" (as defined by the current
ditag Bio::SAGE::DataProcessing::Filter) is retained.

B<Arguments>

I<$sequence>

  The nucleotide sequence of the sequence read to process.

I<$scores> (optional)

  The Phred scores corresponding to the sequence read
  supplied to the method.  The method expects space-separated
  Phred scores (ie. "20 24 54 32" etc.).

B<Returns>

  TRUE (1) if the method was successful, FALSE (0) otherwise.

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new();
  my $sequence = "ACGTACGT";
  my $scores = "20 25 34 12 23 45 51 23";
  if( $sage->process_read( $sequence, $scores ) ) {
    print "Successful!\n";
  }

=cut

    my $this = shift;
    my $read_sequence = shift; # || die( $PACKAGE . "::process_read no sequence specified." );
    my $read_scores = shift;

    if( !defined( $read_sequence ) ) { return 0; }
    if( $read_sequence eq '' ) { return 0; }

    if( $DEBUG >= 1 ) {
        print STDERR $PACKAGE . "::process_read\n";
        print STDERR "  \$read_sequence = $read_sequence\n";
        print STDERR "  \$read_scores   = $read_scores\n";
    }

    $this->{'stats'}->{'total_reads'}++;
    $this->{'stats'}->{'total_bps'} += length( $read_sequence );

    $this->__extract_ditags( $read_sequence, $read_scores );

    return 1;

}

#######################################################
sub get_ditags {
#######################################################
=pod

=head2 get_ditags

Gets the list of currently extracted and valid ditags
stored in this object through calls to process_read.

B<Arguments>

  None.

B<Returns>

  An array of ditag sequences.

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new();
  my $sequence = "ACGTACGT";
  my $scores = "20 25 34 12 23 45 51 23";
  if( $sage->process_read( $sequence, $scores ) ) {
    my @ditags = $sage->get_ditags();
    print "Current ditags:\n";
    map { print "  ".$_."\n" } @ditags;
  }

=cut

    my $this = shift;
    if( $this->{'keep_duplicates'} == 1 ) {
      my @arr;
      foreach my $ditag ( keys %{$this->{'ditags'}} ) {
        for( my $i = 0; $i < scalar( @{$this->{'ditags'}{$ditag}} ); $i++ ) {
          push( @arr, $ditag );
        }
      }
      return @arr;
    }
    return keys %{$this->{'ditags'}};

}

#######################################################
sub get_tags {
#######################################################
=pod

=head2 get_tags

Uses the list of currently extracted and valid ditags
to generate a list of valid SAGE tags.  The default
tag filter (or a filter supplied to set_tag_filter) is
applied during this procedure.

B<Arguments>

  None.

B<Returns>

  An array of tag sequences.

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new();
  my $sequence = "ACGTACGT";
  my $scores = "20 25 34 12 23 45 51 23";
  if( $sage->process_read( $sequence, $scores ) ) {
    my @tags = $sage->get_tags();
    print "Current tags:\n";
    map { print "  ".$_."\n" } @tags;
  }

=cut

    my $this = shift;

    my $enzymeLength = length( $this->{'enzyme'} );
    my $tagLength = $this->{'protocol'}->{'TAG_LENGTH'};
    my @ignoreTags = @{$this->{'protocol'}->{'IGNORE_TAGS'}};

    my @tags;

    foreach my $ditag ( keys %{$this->{'ditags'}} ) {

        my @scoresList;
        if( $this->{'keep_duplicates'} == 1 ) {
          @scoresList = @{$this->{'ditags'}{$ditag}};
        } else {
          $scoresList[0] = ${$this->{'ditags'}}{$ditag};
        }

        #my $scores = ${$this->{'ditags'}}{$ditag};
        foreach my $scores ( @scoresList ) {

            if( $scores eq '' ) {
                # no scores were provided
            }

            my $tag1 = substr( $ditag, $enzymeLength, $tagLength );
            my $bIgnore = 0;
            foreach my $ignoreTag ( @ignoreTags ) {
                if( $ignoreTag eq $tag1 ) {
                    $bIgnore = 1;
                    last;
                }
            }
            if( $bIgnore == 1 ) {
                $this->{'stats'}->{'ignored_tags'}++;
            } else {
                if( $tag1 !~ /^[ACGT]+$/ ) {
                    $this->{'stats'}->{'bad_tags'}++;
                } else {
                    my $tagScores = '';
                    if( $scores ne '' ) {
                        $tagScores = substr( $scores, 0, ( $tagLength+$enzymeLength )*3 );
                    }
                    if( $this->{'tag_filter'}->is_valid( $tag1, $tagScores ) ) {
                        $this->{'stats'}->{'good_tags'}++;
                        push( @tags, $tag1 );
                    } else {
                        $this->{'stats'}->{'lowquality_tags'}++;
                    }
                }
            }

            my $tag2 = substr( $ditag, length( $ditag ) - $tagLength - $enzymeLength, $tagLength );
            $tag2 = reverse( $tag2 );
            $tag2 =~ tr/ACGT/TGCA/;
            $bIgnore = 0;
            foreach my $ignoreTag ( @ignoreTags ) {
                if( $ignoreTag eq $tag2 ) {
                    $bIgnore = 1;
                    last;
                }
            }
            if( $bIgnore == 1 ) {
                $this->{'stats'}->{'ignored_tags'}++;
            } else {
                if( $tag2 !~ /^[ACGT]+$/ ) {
                    $this->{'stats'}->{'bad_tags'}++;
                } else {
                    my $tagScores = '';
                    if( $scores ne '' ) {
                        $tagScores = substr( $scores, (length( $ditag )-$tagLength-$enzymeLength)*3, ($tagLength+$enzymeLength)*3 );
                        $tagScores = join( " ", map { sprintf( "%2i", $_ ) } reverse split( /\s/, $tagScores ) );
                    }
                    if( $this->{'tag_filter'}->is_valid( $tag2, $tagScores ) ) {
                        $this->{'stats'}->{'good_tags'}++;
                        push( @tags, $tag2 );
                    } else {
                        $this->{'stats'}->{'lowquality_tags'}++;
                    }
                }
            }
        }
    }

    return @tags;

}

#######################################################
sub get_tagcounts {
#######################################################
=pod

=head2 get_tagcounts

Extracts valid tags from ditags and returns a hashref
containing tag sequences paired with their respective
counts.

B<Arguments>

None.

B<Returns>

  A hashref where the tag sequence is paired
  with its observed number.

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new();
  my @reads = ( 'ACGTAGACATAGACAAGAGATATAGA',
                'GATAGACAAAGGAAGATTACAAGATTAT' );

  foreach my $read ( @reads ) {
    $sage->process_read( $read );
  }

  # get tag counts
  my %counts = %{$sage->get_tagcounts()};

  # print tag counts
  map { print join( "\t", $_, $counts{$_} ) . "\n" } keys %counts;

=cut

    my $this = shift;

    my %counts;

    my @tags = $this->get_tags();
    map { $counts{$_}++ } @tags;

    return \%counts;

}

#######################################################
sub get_ditag_base_distribution {
#######################################################
=pod

=head2 get_ditag_base_distribution [$minLength], [$maxLength]

Calculates the distribution of bases at each position and both
orientations of a set of ditags.  This distribution is used
for calculating the 'expected' nucleotide count when determining
extra bases using get_extra_base_calculation.

For example:

  CATGAAACCGTATGTAGAGAGGGACACATG
  CATGTAGACAGATAGACACAGATACCATG

has a distribution of:

          +---------------+---------------+
          |    forward    |    reverse    |
    +-----+---+---+---+---+---+---+---+---+
    | pos | A | C | G | T | A | C | G | T |
    +-----+---+---+---+---+---+---+---+---+
    |  0  | 0 | 2 | 0 | 0 | 0 | 2 | 0 | 0 |
    |  1  | 2 | 0 | 0 | 0 | 2 | 0 | 0 | 0 |
    |  2  | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
    |  3  | 0 | 0 | 2 | 0 | 0 | 0 | 2 | 0 |
    |  4  | 1 | 0 | 0 | 1 | 0 | 0 | 1 | 1 |
    |  5  | 2 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
    |  6  | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1 |
    |                    ...              |
    | 28  | 0 | 0 | 1 | 1 | 0 | 0 | 1 | 1 |
    | 29  | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 0 |
    +-----+---+---+---+---+---+---+---+---+

B<Arguments>

I<$minLength> (optional)

  Ignore ditags that are smaller than this minimum length.
  If the argument is not supplied, then the minimum
  ditag length for the currently selected protocol
  is used.

I<$maxLength> (optional)

  Ignore ditags that are larger than this maximum length.
  If the argument is not supplied, then the maximum
  ditag length for the currently selected protocol
  is used.

B<Returns>

  A hashref where the key is the zero-based base position
  index, and the value is a hashref where the key is the
  nucleotide and the value is a hashref where the key is
  either 'fwd' or 'rev' and the value is the count of that
  nucleotide (whew!).

  i.e. $HASH{$idx}->{'A'}->{'fwd'} = 23;

B<Usage>

  my $sage = Bio::SAGE::DataProcessing->new();
  my @ditags = ( 'CATGAAACCGTATGTAGAGAGGGACACATG',
                 'CATGTAGACAGATAGACACAGATACCATG' );

  my %DIST = %{$sage->get_ditag_base_distribution()};

  # print distribution table
  foreach my $idx ( sort { $a <=> $b } keys %DIST ) {
      print $idx . " ";
      print join( " ", map { defined( $DIST{$idx}->{$_} ) ? $DIST{$idx}->{$_} : 0 } ( 'A','C','G','T' ) );
      print "\n";
  }

=cut

    my $this = shift;
    my $minLength = shift || $this->{'protocol'}->{'MINIMUM_DITAG_LENGTH'};
    my $maxLength = shift || $this->{'protocol'}->{'MAXIMUM_DITAG_LENGTH'};

    my %distribution;

    # get forward distribution
    foreach my $ditag ( keys %{$this->{'ditags'}} ) {
        my @bps = split( //, $ditag );
        if( $minLength <= length( $ditag ) && length( $ditag ) <= $maxLength ) {
            for( my $i = 0; $i < length( $ditag ); $i++ ) {
                $distribution{$i}->{$bps[$i]}->{'fwd'}++;
            }
        }
    }

    # get reverse distribution
    foreach my $ditag ( keys %{$this->{'ditags'}} ) {
        $ditag = reverse( $ditag );
        $ditag =~ tr/ACGT/TGCA/;
        my @bps = split( //, $ditag );
        if( $minLength <= length( $ditag ) && length( $ditag ) <= $maxLength ) {
            for( my $i = 0; $i < length( $ditag ); $i++ ) {
                $distribution{$i}->{$bps[$i]}->{'fwd'}++;
            }
        }
    }

    return \%distribution;

}

#######################################################
sub get_ditag_length_distribution {
#######################################################
=pod

=head2 get_ditag_length_distribution

Calculates the distribution of ditag lengths for a set
of ditags.

For example:

  CATGAAACCGTATGTAGAGAGGGACACATG
  CATGTAGACAGATAGACACAGATACCATG
  CATGTATCGCGGCATTACGATCTAGAACATG
  CATGACGACTATATCGATAGCTAACCATG

has a distribution of:

    +-----+---+
    | len | N |
    +-----+---+
    |  29 | 2 |
    |  30 | 1 |
    |  31 | 1 |
    +-----+---+

B<Arguments>

None.

B<Returns>

  A hashref where the key is the ditag length, and
  the value is the number of ditags that have this
  length.

  i.e. $HASH{$len} = 1024;

B<Usage>

  my %DIST = %{$sage->get_ditag_length_distribution()};

  # print distribution table
  foreach my $idx ( sort { $a <=> $b } keys %DIST ) {
      print join( "\t", $idx, $DIST{$idx} ) . "\n";
  }

=cut

    my $this = shift;

    my %dist;
    foreach my $ditag ( keys %{$this->{'ditags'}} ) {
        $dist{length($ditag)}++;
    }

    return \%dist;

}

#######################################################
sub get_extra_base_calculation {
#######################################################
=pod

=head2 get_extra_base_calculation $tag

Calculates the number of times a given nucleotide is
seen at additional positions of a SAGE tag.  This method
is only supported in methods where there the range of
ditag size allows for extra bases to be included in
some (or all) population of ditags.

For example, the ditag sequence:

  CATGTATCGCGGCATTACGATCTAGAACATG

becomes:

  CATGTATCGCGGCA and CATGTTCTAGATCG

but an additonal TTA sequence is stored in the middle.
Some or all of these extra bases may arise from one or
both of the tags.

B<Arguments>

I<$tag>

  The tag sequence that is the focus of the extra base
  calculation.  Only ditags that have this tag sequence
  are considered in the calculation.

  The method checks the length of specified tag and
  checks whether it begins with the expected anchoring
  enzyme site.  If the tag appears to be missing just
  the anchoring enzyme site, it will append this
  automatically.  Otherwise, the method will die.

B<Returns>

  A hashref that is several keys deep in the order:
  extra base position, ditag length, nucleotide.  The
  key is the number of times the keyed event occured.

  In other words:
    $hash->{$position}->{$ditag_length}->{$nucleotide} = $obs;

B<Usage>

  my $dist = $sage->get_extra_base_calculation( "AAACGAATTA" );

  # dump results
  foreach my $ditag_length ( keys %$dist ) {
    foreach my $position ( keys %{$dist->{$ditag_length}} ) {
      foreach my $nucleotide ( keys %{$dist->{$ditag_length}->{$position}} ) {
        print join( ",", $ditag_length, $position, $nucleotide ) .
              "\t" .
              $dist->{$ditag_length}->{$position}->{$nucleotide} .
              "\n";
      }
    }
  }

=cut

  my $this = shift;
  my $tag  = shift || die( $PACKAGE . "::get_extra_base_calculation no tag argument specified." );

  $tag = uc( $tag );

  my $enzyme = $this->{'enzyme'};
  if( !( $tag =~ /^$enzyme/ && length( $tag ) == $this->{'protocol'}->{'TAG_LENGTH'}+length($enzyme) ) ) {
    if( length($tag) == $this->{'protocol'}->{'TAG_LENGTH'} ) {
      $tag = $enzyme . $tag;
    } else {
      die( $PACKAGE . "::get_extra_base_calculation tag '$tag' is not valid." );
    }
  }
  my $revtag = reverse( $tag );
  $revtag =~ tr/ACGT/TGCA/;

  my @ditags = $this->get_ditags();

  my $minDitagLength = 2 * ( length( $enzyme ) + $this->{'protocol'}->{'TAG_LENGTH'} );

  my @data;
  foreach my $ditag ( @ditags ) {

    if( $minDitagLength >= length($ditag) ) {
      next; # ignored because 0 extra bases
    }

    if( $ditag =~ /^$tag/ ) {
      push( @data, $ditag );
      next;
    }
    if( $ditag =~ /$revtag$/ ) {
      $ditag = reverse( $ditag );
      $ditag =~ tr/ACGT/TGCA/;
      push( @data, $ditag );
      next;
    }

  }

  my $taglength = $this->{'protocol'}->{'TAG_LENGTH'} + length($enzyme);

  # TODO: check unlikely event that same tag is sticking together
  # if so, we need to flip the tag in both directions to get extra bases from both
  # directions

  my %results;


  foreach my $ditag ( @data ) {
    $ditag =~ /^.{$taglength}(.*?).{$taglength}$/;

    my @extra_bases = split( //, $1 );

    for( my $i = 0; $i < scalar( @extra_bases ); $i++ ) {
      $results{$i}->{length($ditag)}->{$extra_bases[$i]}++;
    }
  }

  return \%results;

}

#######################################################
sub print_extra_base_calculation {
#######################################################
=pod

=head2 print_extra_base_calculation $resultRef, [$handle]

Prints a formatted report to the specified handle.

An example output looks like:

           +------+------+------+------+
           |   A  |   C  |   G  |   T  |
  +----+---+------+------+------+------+
  | 29 | 0 |  183 |   43 |   31 |   68 |
  | 30 | 0 | 2637 |   23 |   23 |   37 |
  | 31 | 0 | 2624 |    0 |   14 |    0 |
  | 32 | 0 |  665 |    0 |    1 |    0 |
  +----+---+------+------+------+------+
  | 30 | 1 |  639 |  784 |  435 |  862 |
  | 31 | 1 |  188 | 1875 |  198 |  377 |
  | 32 | 1 |    4 |  658 |    0 |    4 |
  +----+---+------+------+------+------+
  | 31 | 2 |  609 |  588 |  355 | 1086 |
  | 32 | 2 |  100 |  204 |  106 |  256 |
  +----+---+------+------+------+------+
  | 32 | 3 |  199 |   95 |   88 |  284 |
  +----+---+------+------+------+------+

The first two columns are the ditag size and the extra
base's relative 0-indexed position, respectively.
The remaining columns are the four nucleotides and the
number of ditags that met the condition described in
the first two columns.

In this example, the investigator could strongly reason
that the extra nucleotides are AC.

B<Arguments>

I<$resultRef>

  A properly formed hashref containing the results of
  an extra base calculation. This data structure can
  be obtained with the get_extra_base_calculation method
  (see the documentation for that method for more details).

I<$handle> (optional)

  A Perl handle to output the results to.  If this
  argument is not specified, STDOUT is used by default.

B<Usage>

  my $dist = $sage->get_extra_base_calculation( "AAACGAATTA" );

  $sage->print_extra_base_calculation( $dist, *STDERR );

=cut

  my $this = shift;
  my $pResults = shift || die( $PACKAGE . "::print_extra_base_calculation result hashref not provided." );
  my $handle = shift || *STDOUT;

  print $handle "         +------+------+------+------+\n";
  my @bps = ('A','C','G','T');
  print $handle join( " | ", "        ", map { "  ".$_." " } @bps ) . " |\n";
  print $handle "+----+---+------+------+------+------+\n";

  foreach my $position ( sort { $a <=> $b } keys %$pResults ) {
    foreach my $ditag_length (  sort { $a <=> $b } keys %{$pResults->{$position}} ) {
      #my @bps = keys %{$pResults->{$ditag_length}->{$position}};
      print $handle "| " . join( " | ", $ditag_length,
                                        $position,
                                        join( " | ",
                                              map { sprintf( "%4i", $pResults->{$position}->{$ditag_length}->{$_} || 0 ) } @bps ) )
                         . " |\n";
    }
    print $handle "+----+---+------+------+------+------+\n";
  }

}

sub __extract_ditags {

    my $this = shift;
    my $read_sequence = shift || die( $PACKAGE . "::__extract_ditags no sequence specified." );
    my $read_scores = shift;

    $read_sequence = uc( $read_sequence );

    if( defined( $read_scores ) ) {
        # make sure scores are padded to two digits
        $read_scores = join( " ", map { sprintf( "%02i", $_ ) } split( /\s+/, $read_scores ) );
    }

    if( $DEBUG >= 1 ) {
        print STDERR $PACKAGE . "::__extract_ditags\n";
        print STDERR "  \$read_sequence = $read_sequence\n";
        print STDERR "  \$read_scores   = $read_scores\n";
    }

    my $enzyme = $this->{'enzyme'};
    my $minLength = $this->{'protocol'}->{'MINIMUM_DITAG_LENGTH'};
    my $maxLength = $this->{'protocol'}->{'MAXIMUM_DITAG_LENGTH'};

    # get position(s) of anchoring enzyme sites
    my $pos = -1;
    my @positions;
    while( ( $pos = index( $read_sequence, $enzyme, $pos ) ) > -1 ) {
        push( @positions, $pos );
        $pos++;
    }

    for( my $i = 0; $i < scalar( @positions )-1; $i++ ) {

        my $ditag_sequence = substr( $read_sequence, $positions[$i], $positions[($i+1)]+length( $enzyme )-$positions[$i] );
        $this->{'stats'}->{'total_ditags'}++;
        if( $ditag_sequence !~ /^[ACGT]+$/ ) {
            $this->{'stats'}->{'badseq_ditags'}++;
            next;
        }
        if( length( $ditag_sequence ) < $minLength ) {
            $this->{'stats'}->{'short_ditags'}++;
            next;
        }
        if( length( $ditag_sequence ) > $maxLength ) {
            $this->{'stats'}->{'long_ditags'}++;
            next;
        }
        my $ditag_scores = undef;
        if( defined( $read_scores ) ) {
            $ditag_scores = substr( $read_scores, $positions[$i]*3, ($positions[($i+1)]+length( $enzyme )-$positions[$i])*3 );
        }
        if( !$this->{'ditag_filter'}->is_valid( $ditag_sequence, $ditag_scores ) ) {
            $this->{'stats'}->{'lowquality_ditags'}++;
            next;
        }
#        }

        if( defined( ${$this->{'ditags'}}{$ditag_sequence} ) && $this->{'keep_duplicates'} == 0 ) {
            # we already have this ditag, which one is better?
            if( defined( $read_scores ) ) {
                my $result = $this->{'ditag_filter'}->compare( $ditag_scores, $this->{'ditags'}{$ditag_sequence} );
                if( $result <= -1 ) {
                    # new one is better
                    $this->{'ditags'}{$ditag_sequence} = $ditag_scores;
                }
            }
            $this->{'stats'}->{'duplicate_ditags'}++;
            next;
        }

        if( $this->{'keep_duplicates'} == 1 ) {
          $this->{'stats'}->{'good_ditags'}++;
          push( @{$this->{'ditags'}{$ditag_sequence}}, $ditag_scores );
          next;
        }

        $this->{'stats'}->{'good_ditags'}++;
        $this->{'ditags'}{$ditag_sequence} = $ditag_scores;

    }

}

sub save {

  my $this = shift;
  my $handle = shift || *STDOUT;

  print $handle '<?xml version="1.0">' . "\n";
  print $handle "<DataProcessing>\n";

  print $handle "  <params>\n";

  print $handle "    <enzyme>" . $this->{'enzyme'} . "</enzyme>\n";
  print $handle "    <keep_duplicates>" . $this->{'keep_duplicates'} . "</keep_duplicates>\n";


  print $handle "  </params>\n";

  print $handle "</DataProcessing>\n";

#    $self->{'enzyme'} = $enzyme;
    #$self->{'protocol'} = $protocol;
    #$self->{'keep_duplicates'} = $bKeepDupes;
#    $self->set_protocol( $protocol );

#    $self->{'ditag_filter'} = $DEFAULT_DITAG_FILTER;
    #$self->{'tag_filter'} = $DEFAULT_TAG_FILTER;



}

sub load {
# make static
}


1;

__END__

=pod

=head1 COPYRIGHT

Copyright(c)2004 Scott Zuyderduyn <scottz@bccrc.ca>. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Scott Zuyderduyn <scottz@bccrc.ca>
BC Cancer Research Centre

=head1 ACKNOWLEDGEMENTS

  Greg Vatcher <gvatcher@bccrc.ca>
  Canada's Michael Smith Genome Sciences Centre <http://www.bcgsc.ca>

=head1 VERSION

  1.20

=head1 SEE ALSO

  Perl(1).

=head1 TODO

  - Add more debugging messages.
  - Method to dump/access statistics collected during processing.

=cut

# Old dependency:
#
#=head1 SEE ALSO
#
#Statistics::Distributions(1).
