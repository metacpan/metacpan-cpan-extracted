#!/usr/bin/env perl

use Bio::BioStudio;
use Getopt::Long;
use Pod::Usage;
use English qw(-no_match_vars);
use CGI qw(:all);

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_ChromosomeAnalyzer_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
			'CHROMOSOME=s'  => \$p{CHROMOSOME},
			'PCG'           => \$p{PCG},
			'NPCG'          => \$p{NPCG},
			'TR'            => \$p{TR},
			'CF'            => \$p{CF},
			'BS'            => \$p{BS},
			'RE'            => \$p{RE},
			'SCOPE=s'       => \$p{SCOPE},
			'START=i'       => \$p{START},
			'STOP=i'        => \$p{STOP},
			'output=s'      => \$p{OUTPUT},
			'help'          => \$p{HELP}
);

################################################################################
################################# SANITY CHECK #################################
################################################################################
pod2usage(-verbose=>99, -sections=>'NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE')
  if ($p{HELP});

die "BSERROR: No chromosome was named.\n"  unless ($p{CHROMOSOME});

my $BS = Bio::BioStudio->new();
my $chr = $BS->set_chromosome(
  -chromosome => $p{CHROMOSOME},
  -gbrowse => $BS->gbrowse()
);

$p{OUTPUT} = "txt" unless $p{OUTPUT};
$p{OUTPUT} = "gbrowse" if $p{OUTPUT} eq 'html';
die "\n BSERROR: format must be txt or gbrowse.\n"
  unless ($p{OUTPUT} eq "txt" || $p{OUTPUT} eq "gbrowse");

die "\n BSERROR: no analyses were indicated.\n"
  unless ($p{CF} || $p{BS} || $p{RE} || $p{TR} || $p{PCG} || $p{NPCG});

$p{SCOPE} = "chrom" unless $p{SCOPE};
die "\n BSERROR: scope must be chrom or seg.\n"
  unless ($p{SCOPE} eq "chrom" || $p{SCOPE} eq "seg");
if ($p{SCOPE} eq "seg" && ( !($p{START} && $p{STOP}) || $p{STOP} <= $p{START}))
{
  die "\n BSERROR: The start and stop coordinates do not parse.\n";
}

################################################################################
################################# CONFIGURING ##################################
################################################################################

my @genes     = $chr->db->get_features_by_type("gene");
my $chrseq    = $chr->sequence();
my $start = $p{SCOPE} eq "seg" ? $p{START} : 1;
my $stop  = $p{SCOPE} eq "seg" ? $p{STOP}  : length($chrseq);
my $range = Bio::Range->new(-start => $start, -end => $stop);
my $disc = " in the region $start..$stop";

my %type_list   = map {$_->method => 1} $chr->db->types;

print "Processing chromosome $p{CHROMOSOME}...\n";
if ($p{OUTPUT} eq "gbrowse")
{
  print "<a href=\"\#PCG\">Protein Coding Genes</a>\n" if ($p{PCG});
  print "<a href=\"\#NPCG\">Non-Protein Coding Genes</a>\n" if ($p{NPCG});
  print "<a href=\"\#TR\">Transposons and Repeat Features</a>\n" if ($p{TR});
  print "<a href=\"\#BS\">Custom BioStudio Features</a>\n" if ($p{BS});
  print "<a href=\"\#CF\">Chromosomal Features</a>\n" if ($p{CF});
  print "<a href=\"\#RE\">Restriction Enzymes</a>\n" if ($p{RE});
  print "<pre>\n";
}

################################################################################
############################ Protein Coding Genes  #############################
################################################################################
if ($p{PCG})
{
  print "\n\n";
  my $head = "Protein Coding Genes";
  print $p{OUTPUT} eq "gbrowse"
    ? h1(a({-name => "PCG"}, "$head")) . br() . "\n"
    : "$head\n";

  my ($REPORT, $FLAT) = $chr->analyze_proteinCodingGenes($start, $stop);

  print print_report($REPORT, $p{OUTPUT});
  print print_flats($FLAT, $p{OUTPUT});
}

################################################################################
############################# Restriction Enzymes  #############################
################################################################################
if ($p{RE})
{
  print "\n\n";
  my $head = "Restriction Enzyme Features";
  print $p{OUTPUT} eq "gbrowse"
    ? h1(a({-name => "RE"}, "$head")) . br() . "\n"
    : "$head\n";

  my ($REPORT, $FLAT) = $chr->analyze_RestrictionEnzymes($start, $stop);

  print print_report($REPORT, $p{OUTPUT});
  print print_flats($FLAT, $p{OUTPUT});
}

################################################################################
########################## non-Protein Coding Genes  ###########################
################################################################################
if ($p{NPCG})
{
  print "\n\n";
  my $head = "Non-Protein Coding Genes";
  print $p{OUTPUT} eq "gbrowse"
    ? h1(a({-name => "NPCG"}, "$head")) . br() . "\n"
    : "$head\n";

  my @npcgs = qw(tRNA rRNA snoRNA snRNA ncRNA pseudogene noncoding_exon
    riboswitch SRP_RNA tmRNA RNAleader group_II_intron RNase_P_RNA);
  my @types   = grep {exists $type_list{$_}} @npcgs;

  my ($REPORT, $FLAT) = $chr->analyze_ArbitraryFeatures($start, $stop, \@types);

  print print_report($REPORT, $p{OUTPUT});
  print print_flats($FLAT, $p{OUTPUT});
}

################################################################################
####################### Transposons and Repeat Features  #######################
################################################################################
if ($p{TR})
{
  print "\n\n";
  my $head = "Transposon and Repeat Features";
  print $p{OUTPUT} eq "gbrowse"
    ? h1(a({-name => "TR"}, "$head")) . br() . "\n"
    : "$head\n";

  my @trs = qw(LTR_retrotransposon transposable_element repeat_region prophage
    transposable_element_gene transposable_element_pseudogene
    long_terminal_repeat);
  my @types   = grep {exists $type_list{$_}} @trs;

  my ($REPORT, $FLAT) = $chr->analyze_ArbitraryFeatures($start, $stop, \@types);

  print print_report($REPORT, $p{OUTPUT});
  print print_flats($FLAT, $p{OUTPUT});
}

################################################################################
########################## Custom BioStudio  Features ##########################
################################################################################
if ($p{BS})
{
  my $BS_FEATS = $BS->custom_features();
  my %bstypes = map {$BS_FEATS->{$_}->primary_tag()} keys %{$BS_FEATS};
  my @types   = grep {exists $type_list{$_}} keys %bstypes;
  push @types, qw(megachunk chunk codon amplicon tag);
  
  print "\n\n";
  my $head = "Custom Features";
  print $p{OUTPUT} eq "gbrowse"
    ? h1(a({-name => "BS"}, "$head")) . br() . "\n"
    : "$head\n";

  my ($REPORT, $FLAT) = $chr->analyze_ArbitraryFeatures($start, $stop, \@types);

  print print_report($REPORT, $p{OUTPUT});
  print print_flats($FLAT, $p{OUTPUT});

}

################################################################################
############################# Chromosomal Features #############################
################################################################################
if ($p{CF})
{
  print "\n\n";
  my $head = "Chromosome Features";
  print $p{OUTPUT} eq "gbrowse"
    ? h1(a({-name => "CF"}, "$head")) . br() . "\n"
    : "$head\n";

  my @cfs = qw(telomere centromere ARS);
  my @types   = grep {exists $type_list{$_}} @cfs;

  my ($REPORT, $FLAT) = $chr->analyze_ArbitraryFeatures($start, $stop, \@types);

  print print_report($REPORT, $p{OUTPUT});
  print print_flats($FLAT, $p{OUTPUT});
}

print "\n\n", "Report generated by $bsversion\n\n";
print "</pre>\n" if ($p{OUTPUT} eq "gbrowse");

exit;

sub print_report
{
  my ($REPORT, $format) = @_;
  my $string = q{};
  foreach my $key (sort keys %{$REPORT})
  {
    my @vals = @{$REPORT->{$key}};
    $string .= scalar(@vals) . " $key";
    $string .= $format eq "gbrowse"  ? (br() . "\n")  : "\n";
    foreach my $ref (@vals)
    {
      my ($obj, $note) = @{$ref};
      my $line = "\t";
      if ($format eq "gbrowse")
      {
       $line .= a({ -href => $chr->gbrowse_feature_link($obj),
                    -target => '_blank',
                    -style => "text-decoration:none"}, $obj->display_name);
        $line .= q{ } . $note . br() . "\n";
      }
      else
      {
        $line .= $obj->display_name;
        $line .= q{ } . $note if ($note);
        $line .= "\n";
      }
      $string .= $line;
    }
    $string .= $format eq "gbrowse"  ? (br() . "\n") x 2  : "\n" x 2;
  }
  return $string;
}

sub print_flats
{
  my ($FLAT, $format) = @_;
  my $string = q{};
  foreach my $key (keys %{$FLAT})
  {
    $string .= "$key:";
    $string .= $format eq "gbrowse"  ? (br() . "\n")  : "\n";
    $string .= $FLAT->{$key};
    $string .= $format eq "gbrowse"  ? (br() . "\n") x 2  : "\n" x 2;
  }
  return $string;
}

__END__

=head1 NAME

  BS_ChromosomeAnalyzer.pl

=head1 VERSION

  Version 2.10

=head1 DESCRIPTION

  This utility provides a broad summary of features in a chromosome. If you ask
   for gbrowse output and have GBrowse enabled, every feature will have a link
   to itself in GBrowse.

  If you choose to analyze protein coding genes, this utility will tell you
   which genes are the smallest or the largest, which genes are essential,
   which genes overlap, which genes have introns, and where the biggest gene
   deserts are. It will also create a codon table and an RSCU value table and
   list any modifications to protein coding genes.

  If you choose to analyze non protein coding genes, transposons and repeat
   features, or chromosome features, you will get a list of features and their
   coordinates.

  If you choose to analyze restriction enzyme recognition sites, you will get a
   list of absent, unique, and rare (2-10 occurrences) restriction enzyme
   recognition sites.

=head1 ARGUMENTS

Required arguments:

  -CH,   --CHROMOSOME : The name of the chromosome to be analyzed

Optional arguments:

  -P,   --PCG   : Analyze protein coding genes
  -N,   --NPCG  : Analyze non protein coding genes
  -T,   --TR    : Analyze transposons and repeat features
  -BS,  --BS    : Analyze custom features specified in BioStudio
  -CF,  --CF    : Analyze other chromosome features
  -RE,  --RE    : Analyze restriction enzyme recognition sites
  -S,   --SCOPE : [seg, chrom (default) The scope of analysis. seg requires
                  START and STOP.
  -STA, --START : The first base for analysis;ignored unless SCOPE = seg
  -STO, --STOP  : The last base for analysis;ignored unless SCOPE = seg
  -O,   --OUTPUT   : Determines if output comes as gbrowse or txt (default)
  -h,   --help     : Display this message

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the BioStudio developers may
not be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut