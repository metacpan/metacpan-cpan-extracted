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
my $bsversion = "BS_auto_filter_CDS_enzymes_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'KEY=s'     => \$p{KEY},
  'CHR=s'     => \$p{CHR},
  'LEFT=s'    => \$p{LEFT},
  'RIGHT=s'   => \$p{RIGHT},
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

my $chr = $BS->set_chromosome(-chromosome => $p{CHR});
$chr->GD->set_restriction_enzymes(-enzyme_set => $pa->{ENZYME_SET});
my $mask = $chr->type_mask('gene');
my $RES = $chr->GD->enzyme_set();

my $redbname = $chr->name() . '_RED';
my $REDB = Bio::BioStudio::RestrictionEnzyme::Store->new(
  -name               => $redbname,
  -enzyme_definitions => $RES
);

my $resultpath = $tmp_path . $p{KEY} . q{_} . $p{LEFT} . q{-} . $p{RIGHT} . '.out';

################################################################################
################################### RUNNING ####################################
################################################################################
my $pool = $REDB->search(-left => $p{LEFT}, -right => $p{RIGHT});
my @res = @{$pool};
my ($drcount, $igcount) = (0, 0);
foreach my $re (@res)
{
  my ($culls, $ignores, $ineligibles) = filter($re, $REDB, $mask, $pa->{CHUNKLENMIN});
  $drcount += $culls;
  $igcount += $ignores;
}
my $arrres = [$drcount, $igcount];
store $arrres, $resultpath;
exit;

__END__

=head1 NAME

  BS_auto_filter_enzymes.pl

=head1 VERSION

  Version 3.00

=head1 DESCRIPTION

   For batch jobs

=cut
