#!/usr/bin/perl

use Bio::BioStudio;
use Getopt::Long;
use Pod::Usage;
use English qw(-no_match_vars);
use CGI qw(:standard);

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_PCRTagDumper_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'CHROMOSOME=s'  => \$p{CHROMOSOME},
  'STARTPOS=i'    => \$p{STARTPOS},
  'STOPPOS=i'     => \$p{STOPPOS},
  'OUTPUT=s'      => \$p{OUTPUT},
  'help'          => \$p{HELP},
);
if ($p{HELP})
{
  pod2usage(
    -verbose=>99,
    -sections=>'NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE'
  );
}

################################################################################
################################# SANITY CHECK #################################
################################################################################
my $BS = Bio::BioStudio->new();

$p{OUTPUT} = $p{OUTPUT} || 'html';
$p{BSVERSION} = $bsversion;

die "BSERROR: No chromosome was named."  if (! $p{CHROMOSOME});
my $chr = $BS->set_chromosome(-chromosome => $p{CHROMOSOME});
my $chrseq = $chr->sequence;
my $chrlen = length $chrseq;
$p{STARTPOS} = $p{STARTPOS} || 1;
$p{STOPPOS} = $p{STOPPOS} || $chrlen;
if ( $p{STOPPOS} <= $p{STARTPOS} )
{
  die "\n ERROR: The start and stop coordinates do not parse.";
}
my $range = $p{STARTPOS} . q{..} . $p{STOPPOS};

################################################################################
################################# CONFIGURING ##################################
################################################################################
my $PCRPRODUCT = qr{\_amp(\d+)}msx;
my $GD = $chr->GD();
my $db = $chr->db();

my @amps = $db->features(
  -range_type => 'contains',
  -types      => 'PCR_product',
  -start      => $p{STARTPOS},
  -end        => $p{STOPPOS},
);
my @genes = $chr->fetch_features(-type => 'gene');
my @nameset = map {$_->display_name} @genes;
my $genenamelength = 0;
foreach my $name (@nameset)
{
  my $currnamelength = length $name;
  $genenamelength = $currnamelength if ($currnamelength > $genenamelength);
}
my $maxlen = $genenamelength + 2;

my $disclaimer = << "END";
All complete amplicons from $p{CHROMOSOME} in the range $range are listed
here in 5'-3' orientation. Percent difference and melting temperatures are
calculated as averages.

CAUTION: if the annotated tag sequence does not match the current sequence, an
asterisk will appear by the amplicon number; see the bottom of the page for the
actual sequence.
END

print $disclaimer, "\n\n";
my $orfspace = 'ORF';
$orfspace .= q{ } while (length $orfspace < $maxlen);
print $orfspace, "Amp#\t5'-3' forward Wild Type   \t  ";
print "5'-3' reverse Wild Type   \t  5'-3' forward Synthetic   \t  ";
print "5'-3' reverse Synthetic   \tSize \t%Diff\tWT Tm\tSyn Tm";
print "\t  Links" if ($BS->{gbrowse} && $p{OUTPUT} eq "html");
print "\n\n";
my @takenotes;

foreach my $amplicon (sort {$a->start <=> $b->start} @amps)
{
  my $warning = 0;
  my $genename = $amplicon->Tag_ingene;
  my $number = 1;
  $number = $1 if ($amplicon =~ $PCRPRODUCT);
  my $intro = $amplicon->Tag_intro;
  my $wtsrc = $chr->species() . $chr->seq_id() . "_$intro";
  my @uptags = $db->features(-name => $amplicon->Tag_uptag);
  my @dntags = $db->features(-name => $amplicon->Tag_dntag);
  my ($uptag, $dntag)   = ($uptags[0], $dntags[0]);
  my ($fwtseq, $rwtseq) = ($uptag->Tag_wtseq, $dntag->Tag_wtseq);
  my ($fmdseq, $rmdseq) = ($uptag->Tag_newseq, $dntag->Tag_newseq);
  my ($fdiff, $rdiff)   = ($uptag->Tag_difference, $dntag->Tag_difference);
  my ($floc, $rloc)     = ($uptag->location(), $dntag->location());

  my $sp1 = q{ } x (28 - length $fwtseq);
  my $sp2 = q{ } x (28 - length $rwtseq );
  my $floclen = $floc->end - $floc->start + 1;
  my $rloclen = $rloc->end - $rloc->start + 1;
  my $f_check = substr $chrseq, $floc->start - $p{STARTPOS}, $floclen;
  my $r_check = substr $chrseq, $rloc->end - $rloclen - $p{STARTPOS} + 1, $rloclen;

  if ($rmdseq ne $r_check)
  {
    $warning++;
    my $warnmsg = "* The current sequence for the reverse synthetic primer ";
    $warnmsg = "of amplicon $number in $genename is $r_check\n";
    push @takenotes, $warnmsg;
  }
  if ($fmdseq ne $f_check)
  {
    $warning++;
    my $warnmsg = "* The current sequence for the forward synthetic primer ";
    $warnmsg = "of amplicon $number in $genename is $f_check\n";
    push @takenotes, $warnmsg;
  }
  my $wtstart = $uptag->Tag_wtpos;
  my $wtend = $wtstart + ($amplicon->end - $amplicon->start + 1) - 1;
  my $disclaimer = $warning > 0  ?  q{*}  :  q{};
  my $diff = int(($rdiff + $fdiff) / 2 + .5);
  my $size = $amplicon->stop - $amplicon->start + 1;
  my $wt_Tm = int( ( $GD->melt($fwtseq) + $GD->melt($rwtseq) ) / 2 + 0.5);
  my $md_Tm = int( ( $GD->melt($fmdseq) + $GD->melt($rmdseq) ) / 2 + 0.5);
  my $geneprint = $genename;
  $geneprint .= q{ } while (length $geneprint < $maxlen);
  print $geneprint, $number, q{ }, $disclaimer, "\t";
  print $fwtseq, "$sp1\t", $GD->complement($rwtseq, 1), "$sp2\t";
  print $fmdseq, "$sp1\t", $GD->complement($rmdseq, 1), "$sp2\t";
  print $size, "  \t  ", $diff, " \t ", $wt_Tm, " \t    ", $md_Tm;
  print "\n";
}

print "\n\n";
print "$_\n" foreach (@takenotes);
print "\n";

exit;

__END__

=head1 NAME

  BS_PCRTagDumper.pl

=head1 VERSION

  Version 2.10

=head1 DESCRIPTION

  This utility creates a list of PCR Tags from a chromosome.  It will alert when
   the sequence for a synthetic tag is not what was expected; this usually means
   that a subsequent edit modified the sequence without considerately updating
   the tags annotation.

=head1 ARGUMENTS

Required arguments:

  -C, --CHROMOSOME : The chromosome to be parsed

Optional arguments:

  -STA, --STARTPOS : The first base for parsing;
  -STO, --STOPPOS  : The last base for parsing;
  -OU,  --OUTPUT   : [html, txt (def)] Format of the output
  -h,   --help : Display this message

=cut
