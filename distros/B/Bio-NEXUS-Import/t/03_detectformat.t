#!/usr/bin/perl -T
# Written by Markus Riester (mriester@gmx.de)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 6th July 2007
use strict;
use warnings;

use Test::More tests => 9;
#use Test::More 'no_plan';
use Data::Dumper;

use Bio::NEXUS::Import;
use Bio::NEXUS::Functions;
use English qw( -no_match_vars );

my %files = ( 
    't/data/01_seqs_sequential.phy' => 'PHYLIP_SEQ_SEQUENTIAL',
    't/data/01_seqs_interleaved.phy' => 'PHYLIP_SEQ_INTERLEAVED',
    't/data/01_seqs_oneline.phy' => 'PHYLIP_SEQ_INTERLEAVED',
    't/data/01_distances_lower.phy' => 'PHYLIP_DIST_LOWER',
    't/data/01_distances_lower_sep_blank.phy' => 'PHYLIP_DIST_LOWER_BLANK',
    't/data/01_distances_square.phy' => 'PHYLIP_DIST_SQUARE_BLANK',
    't/data/01_distances_square_sep_blank.phy' => 'PHYLIP_DIST_SQUARE_BLANK',
    't/data/03_distances.nex' => 'NEXUS',
    't/data/03_sequences.nex' => 'NEXUS',
);

### first testfile


while (my ($file, $format) = each %files) {
    my $nexus = Bio::NEXUS::Import->new();
    my @content = split "\n", _slurp($file);
    my $detected_format = $nexus->_detect_fileformat(\@content);
    is($detected_format, $format, "Format detected") || diag $file;
}    
