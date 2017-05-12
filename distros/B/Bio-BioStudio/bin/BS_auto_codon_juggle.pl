#!/usr/bin/env perl

use Bio::BioStudio;
use Bio::BioStudio::CodonJuggling qw(:BS);
use Storable;
use autodie qw(open close);
use English qw(-no_match_vars);
use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_auto_tag_genes_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'KEY=s' => \$p{KEY},
  'CHR=s' => \$p{CHR},
  'GID=s' => \$p{GID},
	'help'  => \$p{HELP},
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
my $p = retrieve($parampath);

my $chr = $BS->set_chromosome(-chromosome => $p{CHR});
my $mask = $chr->type_mask(['CDS', 'intron']);
my $resultpath = $tmp_path . $p{KEY} . q{_} . $p{GID} . '.out';

################################################################################
################################### RUNNING ####################################
################################################################################
my $results = juggle_gene($chr, $mask, $p{GID}, $p);

store $results, $resultpath;

exit;

__END__

=head1 NAME

  BS_auto_gather_enzymes.pl

=head1 VERSION

  Version 3.00

=head1 DESCRIPTION

   For batch jobs

=cut
