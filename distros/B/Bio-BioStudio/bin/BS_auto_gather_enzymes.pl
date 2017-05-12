#!/usr/bin/env perl

use Bio::BioStudio;
use Bio::BioStudio::RestrictionEnzyme::Seek qw(:BS);
use Storable;
use autodie qw(open close);
use English qw(-no_match_vars);
use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_auto_gather_CDS_enzymes_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'KEY=s'     => \$p{KEY},
  'CHR=s'     => \$p{CHR},
  'FEATURE=s' => \$p{FEATID},
	'help'      => \$p{HELP},
);
pod2usage(-verbose=>99) if ($p{HELP});

################################################################################
################################# SANITY CHECK #################################
################################################################################
die if (! $p{KEY});

my $BS = Bio::BioStudio->new();
my $tmp_path = $BS->tmp_path();

my $parampath = $tmp_path . $p{KEY} . '.param';
die 'No serialized paramfile!' if (! -e $parampath);
my $pa = retrieve($parampath);

my $treepath = $tmp_path . $p{KEY} . '.ptree';
die 'No serialized prefix tree!' if (! -e $treepath);
my $tree = retrieve($treepath);

my $chr = $BS->set_chromosome(-chromosome => $p{CHR});
$chr->GD->set_restriction_enzymes(-enzyme_set => $pa->{ENZYME_SET});
my $feat = $chr->fetch_features(-name => $p{FEATID});
my $RES = $chr->GD->enzyme_set();
my @bees = grep {$_->class eq 'IIB'} values %{$RES};

my $resultpath = $tmp_path . $p{KEY} . q{_} . $p{FEATID} . '.out';

################################################################################
################################### RUNNING ####################################
################################################################################
my $results = undef;
my $besults = undef;
if ($feat && $feat->primary_tag eq 'CDS')
{
  $results = find_enzymes_in_CDS($chr, $tree, $feat);
  $besults = find_IIBs_in_CDS($chr, \@bees, $feat);
}
elsif ($feat)
{
  $results = find_enzymes_in_igen($chr, $feat->start, $feat->end);
}
else
{
  if ($p{FEATID} =~ /igenic\_(\d+)\-(\d+)/)
  {
    my ($fstart, $fend) = ($1, $2);
    $results = find_enzymes_in_igen($chr, $fstart, $fend);
  }
  else
  {
    die "Can't understand feature $p{FEATID}\n";
  }
}

open my $OUT, '>', $resultpath;
my @enzes = defined $results ? @{$results} : ();
my @bnzes = defined $besults ? @{$besults} : ();
foreach my $enz (@enzes, @bnzes)
{
  print {$OUT} $enz->line_report(q{.}, "\n");
}
close $OUT;

exit;

__END__

=head1 NAME

  BS_auto_gather_enzymes.pl

=head1 VERSION

  Version 3.00

=head1 DESCRIPTION

   For batch jobs

=cut
