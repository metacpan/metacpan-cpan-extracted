#!/usr/bin/perl -T
# Written by Markus Riester (markus@bioinf.uni-leipzig.de)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 6th July 2007

use strict;
use warnings;

use Test::More tests => 64;
#use Test::More 'no_plan';
use Data::Dumper;

use Bio::NEXUS::Import;



my ($blocks,$taxa_block, $distances_block);

### first testfile

my $nexus = Bio::NEXUS::Import->new('t/data/01_distances_square.phy');

eval {
      $blocks 		      = $nexus->get_blocks; 			   	
      $taxa_block 	      = $nexus->get_block('taxa');            
      $distances_block    = $nexus->get_block('distances');
};
#warn Dumper $distances_block;
is_deeply($taxa_block->get_taxlabels, [qw(Alpha Beta Gamma Delta Epsilon)],
    '') || diag Dumper $taxa_block->get_taxlabels;

cmp_ok($distances_block->get_distance_between('Alpha', 'Beta'),'==', 1,
    'distance parsed correctly');
cmp_ok($distances_block->get_distance_between('Epsilon', 'Beta'),'==', 3,
    'distance parsed correctly');

$nexus = Bio::NEXUS::Import->new('t/data/01_distances_square_sep_blank.phy');

eval {
      $blocks 		      = $nexus->get_blocks; 			   	
      $taxa_block 	      = $nexus->get_block('taxa');            
      $distances_block    = $nexus->get_block('distances');
};
#warn Dumper $distances_block;
is_deeply($taxa_block->get_taxlabels, [qw(AlphaLONGTAXANAME SHORT Gamma Delta Epsilon)],
    '') || diag Dumper $taxa_block->get_taxlabels;

cmp_ok($distances_block->get_distance_between('AlphaLONGTAXANAME', 'SHORT'),'==', 1,
    'distance parsed correctly');
cmp_ok($distances_block->get_distance_between('Epsilon', 'SHORT'),'==', 3,
    'distance parsed correctly');
### second testfile
$nexus	 = Bio::NEXUS::Import->new('t/data/01_distances_lower.phy', 'PHYLIP_DIST_LOWER');

eval {
      $blocks 		      = $nexus->get_blocks; 			   	
      $taxa_block 	      = $nexus->get_block('taxa');            
      $distances_block    = $nexus->get_block('distances');
};
#warn Dumper $distances_block;
is_deeply($taxa_block->get_taxlabels, ['Mouse',  'Bovine', 'Lemur',
    'Tarsier',  'Squir_Monk'  ,'Jpn_Macaq' ,'Rhesus_Mac' , 'Crab_E.Mac' ,
    'BarbMacaq',  'Gibbon', 'Orang', 'Gorilla', 'Chimp', 'Human'],
    '') || diag Dumper $taxa_block->get_taxlabels;

cmp_ok($distances_block->get_distance_between('Human', 'Chimp'),'==', 0.2712,
    'distance parsed correctly');
cmp_ok($distances_block->get_distance_between('Mouse', 'Human'),'==', 1.7101,
    'distance parsed correctly');

$nexus	 = Bio::NEXUS::Import->new('t/data/01_distances_lower_sep_blank.phy');

eval {
      $blocks 		      = $nexus->get_blocks; 			   	
      $taxa_block 	      = $nexus->get_block('taxa');            
      $distances_block    = $nexus->get_block('distances');
};
#warn Dumper $distances_block;
is_deeply($taxa_block->get_taxlabels, ['MouseWithVeryLongTaxaname',
    'BovineOtherLongTaxaname', 'Lemur',
    'Tarsier',  'Squir_Monk'  ,'Jpn_Macaq' ,'Rhesus_Mac' , 'Crab_E.Mac' ,
    'BarbMacaq',  'Gibbon', 'Orang', 'Gorilla', 'Chimp', 'Human'],
    '') || diag Dumper $taxa_block->get_taxlabels;

cmp_ok($distances_block->get_distance_between('Human', 'Chimp'),'==', 0.2712,
    'distance parsed correctly');
cmp_ok($distances_block->get_distance_between('MouseWithVeryLongTaxaname', 'Human'),'==', 1.7101,
    'distance parsed correctly');



$nexus	 = Bio::NEXUS::Import->new('t/data/01_distances_microsat.phy');


eval {
      $blocks 		      = $nexus->get_blocks; 			   	
      $taxa_block 	      = $nexus->get_block('taxa');            
      $distances_block    = $nexus->get_block('distances');
};
#warn Dumper $distances_block;
is_deeply($taxa_block->get_taxlabels, ['CAM',  'CAR', 'CIN', ],
    '') || diag Dumper $taxa_block->get_taxlabels;

cmp_ok($distances_block->get_distance_between('CAM', 'CAR'),'==', 16.252,
    'distance parsed correctly');
cmp_ok($distances_block->get_distance_between('CIN', 'CAM'),'==', 11.003,
    'distance parsed correctly');




### third to 5th testfile

my @files = ( 
    't/data/01_seqs_sequential.phy:PHYLIP_SEQ_SEQUENTIAL',
    't/data/01_seqs_interleaved.phy:PHYLIP_SEQ_INTERLEAVED',
    't/data/01_seqs_oneline.phy:PHYLIP_SEQ_SEQUENTIAL',
    't/data/01_seqs_oneline.phy:PHYLIP_SEQ_INTERLEAVED',
    't/data/01_seqs_sequential.phy:',
    't/data/01_seqs_interleaved.phy:',
    't/data/01_seqs_oneline.phy:',
);

my %data = (
    'Turkey'     => 'AAGCTNGGGCATTTCAGGGTGAGCCCGGGCAATACAGGGTAT',
    'Salmo_gair' => 'AAGCCTTGGCAGTGCAGGGTGAGCCGTGGCCGGGCACGGTAT',
    'H._Sapiens' => 'ACCGGTTGGCCGTTCAGGGTACAGGTTGGCCGTTCAGGGTAA',
    Chimp        => 'AAACCCTTGCCGTTACGCTTAAACCGAGGCCGGGACACTCAT',
    Gorilla      => 'AAACCCTTGCCGGTACGCTTAAACCATTGCCGGTACGCTTAA',
);

foreach (@files) {
    my ($file, $format) = split ':';
    $format = undef if $format eq '';
    my $chars_block;
    $nexus	 = Bio::NEXUS::Import->new($file, $format);
    eval {
        $blocks 		      = $nexus->get_blocks; 			   	
        $taxa_block 	      = $nexus->get_block('taxa');            
        $chars_block    = $nexus->get_block('characters');
    };
    #warn Dumper $distances_block;
    is_deeply($taxa_block->get_taxlabels, ['Turkey',  'Salmo_gair', 'H._Sapiens',
        'Chimp',  'Gorilla'  ],
        '') || diag Dumper $taxa_block->get_taxlabels;

    cmp_ok($chars_block->get_nchar,'==', 42,
        'nchar parsed correctly')
        || diag "FAILED for file $file ($format).\n";

    my $otuset = $chars_block->get_otuset();
    for my $i (0 .. scalar(@{$taxa_block->get_taxlabels})-1) {
        my $otu   = $otuset->get_otus->[$i];
        my $label = $taxa_block->get_taxlabels->[$i];
        cmp_ok($otu->get_seq_string, 'eq',
            $data{$label}, 'Sequence correct')
        || diag "FAILED for taxon $label, file $file ($format).\n";
    }    
    $nexus->write('tmp',1);
}
