#!/usr/bin/env perl

use Bio::GeneDesign;
use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '5.56';
my $GDV = "GD_Filter_Enzymes$VERSION";

local $| = 1;

##Get Arguments
my %p = ();
GetOptions (
      'help'            => \$p{HELP},
      'enzymelist'      => \$p{LIST},
      'sticky=s'        => \$p{STICKY},
      'palindromy=s'    => \$p{PAL},
      'length=s'        => \$p{LENGTH},
      'ambiguous=s'     => \$p{AMBIG},
      'inactivation=i'  => \$p{INACT},
      'incubation=s'    => \$p{TEMP},
      'staractivity=s'  => \$p{STAR},
      'cpgsense=s'      => \$p{CPG},
      'damsense=s'      => \$p{DAM},
      'dcmsense=s'      => \$p{DCM},
      'buffer=s'        => \$p{BUFF},
      'vendor=s'        => \$p{VEND},
      'pricemax=f'      => \$p{PRICEMAX},
      'seqmusthave=s'   => \$p{REQSEQ},
      'seqmaynothave=s' => \$p{DISSEQ}
);

################################################################################
################################# CONFIGURING ##################################
################################################################################
pod2usage(-verbose=>99, -sections=>"DESCRIPTION|ARGUMENTS") if ($p{HELP});

my $GD = Bio::GeneDesign->new();
$p{LIST} = $p{LIST} || "standard_and_IIB";
$GD->set_restriction_enzymes(-enzyme_set => $p{LIST});

my $RES = $GD->enzyme_set;

################################################################################
################################## FILTERING ###################################
################################################################################

if ($p{STICKY})
{
  my @sticks = split(",", $p{STICKY});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ($re->filter_by_stickiness(\@sticks));
  }
}

if ($p{PAL})
{
  my @pals = split(",", $p{PAL});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ($re->filter_by_overhang_palindromy(\@pals));
  }
}

if ($p{LENGTH})
{
  my @lens = split(",", $p{LENGTH});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ($re->filter_by_length(\@lens));
  }
}

if ($p{AMBIG})
{
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ($re->filter_by_base_ambiguity($p{AMBIG}));
  }
}

if ($p{INACT})
{
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ($re->filter_by_inactivation_temperature($p{INACT}));
  }
}

if ($p{TEMP})
{
  my @temps = split(",", $p{TEMP});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ($re->filter_by_incubation_temperature(\@temps));
  }
}

if ($p{STAR})
{
  my $star = $p{STAR};
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ( $re->filter_by_star_activity($p{STAR}) );
  }
}

if ($p{CPG})
{
  my @senses = split(",", $p{CPG});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ( $re->filter_by_cpg_sensitivity(\@senses) );
  }
}

if ($p{DAM})
{
  my @senses = split(",", $p{DAM});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ( $re->filter_by_dam_sensitivity(\@senses) );
  }
}

if ($p{DCM})
{
  my @senses = split(",", $p{DCM});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ( $re->filter_by_dcm_sensitivity(\@senses) );
  }
}

if ($p{BUFF})
{
  my %buffs;
  foreach my $buffpair (split(",", $p{BUFF}))
  {
    my ($buff, $val) = split("=", $buffpair);
    $buffs{$buff} = $val;
  }
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ( $re->filter_by_buffer_activity(\%buffs) );
  }
}

if ($p{VEND})
{
  my @vends = split(",", $p{VEND});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ( $re->filter_by_vendor(\@vends) );
  }
}

if ($p{PRICEMAX})
{
  unless ($p{PRICEMAX} =~ /^-?(?:\d+\.?|\.\d)\d*\z/ && $p{PRICEMAX} >= 0)
  {
    print "\tWARNING: Can't parse price argument $p{PRICEMAX} - ignoring.\n";
  }
  else
  {
    foreach my $id (keys %$RES)
    {
      my $re = $RES->{$id};
      delete $RES->{$id} unless ( $re->filter_by_score($p{PRICEMAX}) );
    }
  }
}

if ($p{REQSEQ})
{
  my @reqs = split (",", $p{DISSEQ});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ( $re->filter_by_sequence(\@reqs) );
  }
}

if ($p{DISSEQ})
{
  my @disses = split (",", $p{DISSEQ});
  foreach my $id (keys %$RES)
  {
    my $re = $RES->{$id};
    delete $RES->{$id} unless ( $re->filter_by_sequence(\@disses, 1) );
  }
}

################################################################################
################################## REPORTING ###################################
################################################################################

unless (scalar (keys %$RES))
{
  die "GDERROR: No enzymes survived filtration.\n";
}

print "\n\nFOUND ", scalar (keys %$RES), " ENZYMES\n\n";
foreach my $reid (sort {$RES->{$a}->score <=> $RES->{$b}->score} keys %$RES)
{
  my $re = $RES->{$reid};
  print $re->display . "\n";
}

print "\n\n";
exit;

__END__

=head1 NAME

  GD_Filter_Enzymes.pl

=head1 VERSION

  Version 5.56

=head1 DESCRIPTION

  Creates a list of restriction enzymes that meet optionally provided criteria.
  Any criteria left blank will not be used to filter the results.

=head1 USAGE

  List all enzymes that leave non-1bp overhangs and cut inside recognition seq:
        GD_Filter_Enzymes.pl --sticky 35 --cleavage in

  List all enzymes that are available from NEB or Stratagene and are inactivated
  at or below 60 deg and cost less than 50 cents a unit:
        GD_Filter_Enzymes.pl --vendor N,E --inactivation 60 --pricemax .5

  List all enzymes that have at least 25% activity in NEB buffers 1 and 4 and
  are indifferent to CpG methylation
        GD_Filter_Enzymes.pl --buffer NEB1=25,NEB4=25 --cpgsense indifferent

  List all enzymes that exhibit star activity and are blocked or inhibited by
  Dam methylation
        GD_Filter_Enzymes.pl --staractivity 1 --damsense blocked,inhibited

  List all enzymes that may leave nonpalindromic overhangs (and those that
  definitely do) and whose recognition sequences do not contain AT or TA
        GD_Filter_Enzymes.pl --palindromy pnon,nonpal --seqmaynothave AT,TA

=head1 ARGUMENTS

Optional arguments:

  -h,   --help : Display this message
  -enzymelist     : The name of an enzyme set to use in configuration, defaults
                    to standard_and_IIB
  --sticky        : [1, 3, 5, b] What type of overhang is left by the enzyme
  --palindromy    : [pal, pnon, nonpal] Is the overhang left by the enzyme
                    palindromic, potentially non-palindromic, or non-palindromic
  --length        : How many bases long is the recognition site allowed to be,
                    accepts a comma separated list
  --ambiguous     : [nonNonly OR ATCGonly] Are ambiguous bases allowed in the
                    recognition site. If yes to all, don't include this option
  --inactivation  : Enzymes must be inactivated by at least this temperature
  --incubation    : Enzymes must incubate at this temperature
  --staractivity  : [1 OR 0] Enzymes with or without star activity
  --cpgsense      : [blocked, inhibited, indifferent] Sensitivity to CpG
                    methylation
  --damsense      : [blocked, inhibited, indifferent] Sensitivity to Dam
                    methylation
  --dcmsense      : [blocked, inhibited, indifferent] Sensitivity to Dcm
                    methylation
  --buffer        : List of buffer activity thresholds. NEB1=50,NEB2=50 means
                    enzymes must have at least 50% activity in NEB buffers 1 & 2
                    Other=50 will work for non NEB buffers
  --pricemax      : The highest amount in dollars/unit an enzyme can cost
  --seqmusthave   : List of sequences that must be found in the recognition site
  --seqmaynothave : List of sequences that must not be in the recognition site
  --vendor        : List of vendors that must stock the enzyme, using the
                    comma separated abbreviations:
                        B = Invitrogen
                        C = Minotech
                        E = Stratagene
                        F = Thermo Scientific Fermentas
                        I = SibEnzyme
                        J = Nippon Gene Co.
                        K = Takara
                        M = Roche Applied Science
                        N = New England Biolabs
                        O = Toyobo Technologies
                        Q = Molecular Biology Resources
                        R = Promega
                        S = Sigma Aldrich
                        U = Bangalore Genei
                        V = Vivantis
                        X = EURx
                        Y = CinnaGen
=cut