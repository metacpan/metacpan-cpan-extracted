#!/usr/bin/env perl

use Bio::BioStudio;
use Getopt::Long;
use Pod::Usage;
use English qw(-no_match_vars);

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_SeqChecker_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'CHROMOSOME=s'  => \$p{CHROMOSOME},
  'OUTPUT=s'      => \$p{OUTPUT},
	'help'          => \$p{HELP}
);
pod2usage(-verbose=>99) if ($p{HELP});

################################################################################
################################# SANITY CHECK #################################
################################################################################
my $BS = Bio::BioStudio->new();

$p{OUTPUT} = $p{OUTPUT} || 'txt';

die "BSERROR: No chromosome was named" if (! $p{CHROMOSOME});
my $chr = $BS->set_chromosome(-chromosome => $p{CHROMOSOME});

################################################################################
################################# CONFIGURING ##################################
################################################################################
$p{BSVERSION} = $bsversion;
my $BS_FEATS = $BS->custom_features();
my %BSKINDS = map {$BS_FEATS->{$_}->primary_tag => $_} keys %{$BS_FEATS};
my @keys = keys %BSKINDS;

################################################################################
############################### ERROR  CHECKING ################################
################################################################################
print "Checking ", $chr->name(), "\n";
my $GD = $chr->GD();
my $chrseq = $chr->sequence();
my @features = $chr->db->features();
foreach my $feat (@features)
{
  my $fname = $feat->display_name;
  my $ftype = $feat->primary_tag;
  my $trueseq = $feat->seq->seq;
  my $realseq = substr $chrseq, $feat->start - 1, $feat->end - $feat->start + 1;
  if ($feat->has_tag('newseq'))
  {
    my $annseq = $feat->Tag_newseq;
    if ($annseq ne $trueseq)
    {
      print "WARNING: $fname has bad newseq tag!\n";
      print "\t$annseq tag vs $trueseq actual\n";
    }
  }
  my $shouldseq = undef;
  if ($feat->has_tag('custom_feature'))
  {
    my $proto = $feat->Tag_custom_feature;
    my $bshsh = $BS_FEATS->{$proto};
    $shouldseq = $bshsh->{default_sequence};
  }
  elsif (exists $BSKINDS{$ftype})
  {
    foreach my $customname (keys %{$BS_FEATS})
    {
      if ($fname =~ $customname)
      {
        $shouldseq = $BS_FEATS->{$customname}->{default_sequence};
        last;
      }
    }
  }
  if (defined $shouldseq)
  {
    $trueseq = $GD->rcomplement($trueseq) if ($feat->strand == -1);
    if ($shouldseq ne $trueseq)
    {
      print "WARNING: $feat sequence looks weird!\n";
      print "\t$realseq, $shouldseq != $trueseq actual\n";
    }
  }

}
print "\n";

exit;

__END__

=head1 NAME

  BS_SeqChecker.pl

=head1 VERSION

  Version 2.10

=head1 DESCRIPTION

  This utility checks the sequences of the features in a chromosome against
  their annotations and against the expected sequences found in BioStudio
  configuration.

=head1 ARGUMENTS

Required arguments:

  -C,   --CHROMOSOME : The chromosome to be checked

Optional arguments:

  -O,   --OUTPUT : [html, txt (def)] Format for reporting and output
  -h,   --help : Display this message
 
=cut
