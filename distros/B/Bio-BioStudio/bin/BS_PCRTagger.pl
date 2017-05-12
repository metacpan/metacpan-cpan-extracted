#!/usr/bin/env perl

use Bio::BioStudio;
use Bio::BioStudio::PCRTagging qw(:BS);
use Getopt::Long;
use Pod::Usage;
use Readonly;
use English qw(-no_match_vars);
use Carp;

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_PCRTagger_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'CHROMOSOME=s'      => \$p{CHROMOSOME},
  'EDITOR=s'          => \$p{EDITOR},
  'MEMO=s'            => \$p{MEMO},
  'ITERATE=s'         => \$p{ITERATE},
  'STARTPOS=i'        => \$p{STARTPOS},
  'STOPPOS=i'         => \$p{STOPPOS},
  'MINTAGMELT=i'      => \$p{MINTAGMELT},
  'MAXTAGMELT=i'      => \$p{MAXTAGMELT},
  'MINTAGLEN=i'       => \$p{MINTAGLEN},
  'MAXTAGLEN=i'       => \$p{MAXTAGLEN},
  'MINAMPLEN=i'       => \$p{MINAMPLEN},
  'MAXAMPLEN=i'       => \$p{MAXAMPLEN},
  'MAXAMPOLAP=i'      => \$p{MAXAMPOLAP},
  'MINPERDIFF=i'      => \$p{MINPERDIFF},
  'MINORFLEN=i'       => \$p{MINORFLEN},
  'FIVEPRIMESTART=i'  => \$p{FIVEPRIMESTART},
  'MINRSCUVAL=f'      => \$p{MINRSCUVAL},
  'OUTPUT=s'          => \$p{OUTPUT},
  'help'              => \$p{HELP}
);
$p{BSVERSION} = $bsversion;


################################################################################
################################# SANITY CHECK #################################
################################################################################
pod2usage(-verbose=>99, -sections=>'NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE')
  if ($p{HELP});

my $BS = Bio::BioStudio->new();
if (! $BS->BLAST())
{
  die "Cannot make PCR tags: blast support is not enabled\n";
}

if (! $p{EDITOR} || ! $p{MEMO})
{
  die "\n ERROR: Both an editor's id and a memo must be supplied.\n\n";
}
if ($BS->SGE())
{
  require EnvironmentModules;
  import EnvironmentModules;
  module('load openmpi');
  module('load taskfarmermq/2.4');
  module('load biostudio');
  module('load blast+');
}

die "BSERROR: No chromosome was named.\n"  if (! $p{CHROMOSOME});
my $chr    = $BS->set_chromosome(-chromosome => $p{CHROMOSOME});
my $chrseq = $chr->sequence;
my $chrlen = length $chrseq;
my $GD = $chr->GD;

Readonly my $ITERATE          => 'chromosome';
Readonly my $OUTPUT           => 'txt';
Readonly my $MINTAGMELT       => 57.9;
Readonly my $MINMINTAGMELT       => 20;
Readonly my $MAXTAGMELT       => 60.9;
Readonly my $MAXMAXTAGMELT       => 90;
Readonly my $MINPERDIFF       => 33;
Readonly my $MINMINPERDIFF       => 20;
Readonly my $MAXMINPERDIFF       => 66;
Readonly my $MINTAGLEN        => 19;
Readonly my $MAXTAGLEN        => 28;
Readonly my $MINAMPLEN        => 200;
Readonly my $MAXAMPLEN        => 500;
Readonly my $MAXAMPOLAP       => 25;
Readonly my $MINORFLEN        => 501;
Readonly my $FIVEPRIMEBUFFER  => 101;
Readonly my $THREEPRIMEBUFFER => 0;
Readonly my $MINRSCUVAL       => 0.04;
Readonly my $ORF_TAG_INC      => 1000;

$p{OUTPUT}           = $p{OUTPUT}           || $OUTPUT;
$p{ITERATE}          = $p{ITERATE}          || $ITERATE;
$p{MINTAGMELT}       = $p{MINTAGMELT}       || $MINTAGMELT;
$p{MAXTAGMELT}       = $p{MAXTAGMELT}       || $MAXTAGMELT;
$p{MINPERDIFF}       = $p{MINPERDIFF}       || $MINPERDIFF;
$p{MINTAGLEN}        = $p{MINTAGLEN}        || $MINTAGLEN;
$p{MAXTAGLEN}        = $p{MAXTAGLEN}        || $MAXTAGLEN;
$p{MINAMPLEN}        = $p{MINAMPLEN}        || $MINAMPLEN;
$p{MAXAMPLEN}        = $p{MAXAMPLEN}        || $MAXAMPLEN;
$p{MAXAMPOLAP}       = $p{MAXAMPOLAP}       || $MAXAMPOLAP;
$p{MINORFLEN}        = $p{MINORFLEN}        || $MINORFLEN;
$p{MINRSCUVAL}       = $p{MINRSCUVAL}       || $MINRSCUVAL;
$p{STARTPOS}         = $p{STARTPOS}         || 1;
$p{STOPPOS}          = $p{STOPPOS}          || $chrlen;
$p{ORF_TAG_INC}      = $p{ORF_TAG_INC}      || $ORF_TAG_INC;
$p{FIVEPRIMEBUFFER}  = $p{FIVEPRIMEBUFFER}  || $FIVEPRIMEBUFFER;
$p{FIVEPRIMEBUFFER}++ while ($p{FIVEPRIMEBUFFER} % 3 != 0);
$p{THREEPRIMEBUFFER} = $p{THREEPRIMEBUFFER} || $THREEPRIMEBUFFER;
$p{THREEPRIMEBUFFER}++ while ($p{THREEPRIMEBUFFER} % 3 != 0);


if ($p{STOPPOS} <= $p{STARTPOS})
{
  die "\n ERROR: The start and stop coordinates do not parse.\n\n";
}

if ( $p{MAXTAGMELT} < $p{MINTAGMELT}
  || $p{MAXTAGMELT} >= $MAXMAXTAGMELT || $p{MINTAGMELT} <= $MINMINTAGMELT)
{
  die "\n ERROR: The tag melting parameters do not parse.\n\n";
}

if ($p{MAXTAGLEN} < $p{MINTAGLEN} || $p{MINTAGLEN} <= 0 ||
  ((($p{MAXTAGLEN} - 1) % 3 != 0 ) || (($p{MINTAGLEN} - 1) % 3 != 0)))
{
  die "\n ERROR: The tag length parameters do not parse. Tag lengths must be "
    . "multiples of 3 plus 1.\n\n";
}

if ($p{MAXAMPLEN} < $p{MINAMPLEN} || $p{MINAMPLEN} <= 0)
{
  die "\n ERROR: The amplicon length parameters do not parse.\n\n";
}

if ($p{MINPERDIFF} > $MAXMINPERDIFF || $p{MINPERDIFF} <= $MINMINPERDIFF )
{
  die "\n ERROR: The minimum percent difference does not parse.\n\n";
}

if ($p{ITERATE} ne 'genome' && $p{ITERATE} ne 'chromosome')
{
  die "BSERROR: Argument to iterate must be 'genome' or 'chromosome'.\n";
}

#Single family codons can't be first or last codons
#codons that don't share their siblings' first two bases can't be first codons
my %fams;
my %dicodons;
my $codon_t = $GD->codontable;
foreach my $cod (keys %{$codon_t})
{
  my $aa = $codon_t->{$cod};
  $fams{$aa} = [] if (! exists $fams{$aa});
  $dicodons{$aa} = {} if (! exists $dicodons{$aa});
  push @{$fams{$aa}}, $cod if ($GD->rscutable->{$cod} > $p{MINRSCUVAL});
  $dicodons{$aa}->{substr $cod, 0, 2}++;
}
my %badfirstaas = map {$_ => 1} grep { scalar(@{$fams{$_}}) == 1 } keys %fams;
foreach my $aa (grep {scalar (@{$fams{$_}}) > 1} keys %dicodons)
{
  my $flag = 0;
  foreach (keys %{$dicodons{$aa}})
  {
    $flag++ if ($dicodons{$aa}->{$_} == 1);
  }
  $badfirstaas{$aa}++ if ($flag != 0);
}
$p{BADAAS} = \%badfirstaas;
#print "bads: ", keys %badfirstaas, "\n\n";

################################################################################
################################# CONFIGURING ##################################
################################################################################
my $newchr = $chr->iterate(-version => $p{ITERATE});

my $genome = $BS->gather_latest_genome($chr->species);
my $result = $BS->SGE
  ? farm_tagging($newchr, $genome, \%p)
  : serial_tagging($newchr, $genome, \%p);
my %report = %{$result};

#Do error checking
my $newseq = $newchr->sequence;
my @genes = $newchr->db->features(
  -types      => 'gene',
  -start      => $p{STARTPOS},
  -end        => $p{STOPPOS},
  -range_type => 'contains'
);
foreach my $gene (@genes)
{
  my $gstart = $gene->start;
  my $gend = $gene->end;
  my $glen = $gend - $gstart + 1;
  my $gid = $gene->Tag_load_id;
  my $newgeneseq = substr $newseq, $gstart - 1, $glen;
  my $oldgeneseq = substr $chrseq, $gstart - 1, $glen;
  if ($newgeneseq eq $oldgeneseq)
  {
    $report{$gid} .= ' No change in sequence;';
  }
  my $cdna = $chr->make_cDNA($gene);
  my $oldpep = $GD->translate(-sequence => $cdna);
  my $newcdna = $newchr->make_cDNA($gene);
  my $newpep = $GD->translate(-sequence => $newcdna);
  if ($newpep ne $oldpep)
  {
    $report{$gid} .= ' Change in amino acid sequence;';
  }
}
print "\n\n";

foreach my $gid (sort keys %report)
{
  print "$gid : $report{$gid}\n";
}

#Tell chromosome to write itself
$newchr->add_reason($p{EDITOR}, $p{MEMO});
$newchr->write_chromosome();

exit;

__END__


=head1 NAME

  BS_PCRTagger.pl

=head1 VERSION

  Version 3.00

=head1 DESCRIPTION

  This utility creates unique tags for open reading frames to aid the analysis
    of synthetic content in a nascent synthetic genome. Each tag in a gene has
    a wildtype and a synthetic version that correspond to the same offset in the
    gene; each tag can be paired with another to form gene specific amplicons
    which are also specific to either wildtype or synthetic sequence, depending
    on which tags are used.

  To pick tags for a chromosome, each open reading frame over I<MINORFLEN> base
   pairs long will be slightly recoded to contain a set of PCR tags. The
   locations and sequences of these tags are carefully chosen to maximize the
   selectivity of the tags for either wild type or synthetic sequence. Each wild
   type or synthetic tag and its reverse complement are unique in the entire
   wild type genome; this is accomplished by creating a BLAST database for the
   entire wild type genome and BLASTing each potential tag against it (this
   requires that a complete wild type genome is available in the BioStudio
   repository). Pairs of tags are selected in such a way that they will not
   amplify any other genomic sequence under 1000 bases long. Each synthetic
   counterpart to a wild type tag is recoded with GeneDesign's "most different"
   algorithm to guarantee maximum nucleotide sequence difference while
   maintaining identical protein sequence and, hopefully, minimizing any effect
   on gene expression. The synthetic tags are all at least I<MINPERDIFF> percent
   recoded from the wild type tags. Each tag is positioned in such a way that
   the first and last nucleotides correspond to the wobble of a codon that can
   be edited to change its wobble without changing its amino acid.  This usually
   automatically excludes methionine or tryptophan, but it can exclude others
   when a I<MINRSCUVAL> filter is in place. The wobble restriction ensures that
   the synthetic and wild type counterparts have different 5' and 3'
   nucleotides, minimizing the chances that they (and their complements) will
   cross-prime. This means that tags will be between I<MINTAGLEN> and
   I<MAXTAGLEN> base pairs long, where I<TAGLEN> is a multiple of 3 plus 1. All
   tags have melting temperature between I<MINTAGMELT> and I<MAXTAGMELT> so they
   can be used in a single set of PCR conditions.

  Tag pairs are chosen to form amplicons specific for each ORF, with at least
   one amplicon chosen per kilobase of ORF. Each amplicon is between
   I<MINAMPLEN> and I<MAXAMPLEN> base pairs long, ensuring that they will all
   fall within an easily identifiable range on an agarose gel. No amplicon will
   be chosen within the first I<FIVEPRIMESTART> base pairs of an ORF to avoid
   disrupting unknown regulatory features. Amplicons are forbidden from
   overlapping each other by more than I<MAXAMPOLAP> percent.

=head1 ARGUMENTS

Required arguments:

  -C, --CHROMOSOME : The chromosome to be modified
  -E, --EDITOR : The person responsible for the edits
  -ME, --MEMO : Justification for the edits

Optional arguments:

  --ITERATE : [genome, chromosome (def)] Which version number to increment?
  -STA, --STARTPOS : The first base for analysis;
  -STO, --STOPPOS  : The last base for analysis;
  --MINTAGMELT : (default 58) Minimum melting temperature for tags
  --MAXTAGMELT : (default 60) Maximum melting temperature for tags
  --MINPERDIFF : (default 33) Minimum base pair difference between synthetic and
                 wildtype versions of a tag
  --MINTAGLEN  : (default 19) Minimum length for tags. Must be a multiple of 3,
                 plus 1
  --MAXTAGLEN  : (default 28) Maximum length for tags. Must be a multiple of 3,
                 plus 1
  --MINAMPLEN  : (default 200) Minimum span for a pair of tags
  --MAXAMPLEN  : (default 500) Maximum span for a pair of tags
  --MAXAMPOLAP : (default 25) Maximum percentage of overlap allowed between
                 different tag pairs
  --MINORFLEN  : (default 501) Minimum size of gene for tagging eligibility
  --FIVEPRIMESTART : (default 101) The first base in a gene eligible for a tag
  --MINRSCUVAL : (default 0.06) The minimum RSCU value for any replacement codon
                 in a tag
  --OUTPUT    : [html, txt (def)] Format of reporting and output.
  -h, --help : Display this message

=cut