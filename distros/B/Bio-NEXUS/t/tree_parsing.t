#!/usr/bin/perl -w

######################################################
#
# original author Vivek Gopalan (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;
use Bio::NEXUS;

my ($tree,$tree_block);

    my $file_names = [
"trees-tree-basal-trifurcation.nex",
"trees-tree-bush.nex",
"trees-tree-bush-branchlength-negative.nex",
"trees-tree-bush-branchlength-scientific.nex",
"trees-tree-bush-branchlength-zero.nex",
"trees-tree-bush-cladogram.nex",
"trees-tree-bush-extended-root-branch.nex",
"trees-tree-bush-inode-labels.nex",
"trees-tree-bush-inode-labels-partial.nex",
"trees-tree-bush-inode-labels-quoted2.nex",
"trees-tree-bush-quoted-string-name2.nex",
"trees-tree-bush-uneven.nex",
"trees-tree-ladder.nex",
"trees-tree-ladder-cladogram.nex",
"trees-tree-ladder-uneven.nex",
"trees-tree-rake-cladogram.nex"
];

my $nexus_obj;
foreach my $file_name (@{$file_names}) {

   my $tree_name = $file_name;
      $tree_name =~ s/trees-tree-//;
      $tree_name =~ s/\.nex//;
      $tree_name =~s/-/_/g; 
   print $file_name," (", $tree_name, ")\n";
   $file_name = "t/data/compliant/".$file_name;
      
eval {
   $nexus_obj = new Bio::NEXUS( $file_name );
   $tree_block = $nexus_obj->get_block('trees');
};

   is( $@,'', 'TreesBlock object created and parsed');                # check that we got something
   plan skip_all => "Problem reading NEXUS file" if $@;

   $tree = $tree_block->get_tree();
   my $no_of_nodes;
   my $otus = 8;
   if ($tree_name =~/rake/) { ## sets the total number of nodes different types of trees
      $no_of_nodes = 9;
   } elsif ($tree_name =~/trifurcation/){
      $no_of_nodes = 14;
   } else {
      $no_of_nodes = 15;
   }

   is(@{$tree->get_nodes},$no_of_nodes,"$no_of_nodes nodes defined: ". $otus. " otus + " . ($no_of_nodes-$otus) . " root");
   is(@{$tree->get_node_names},$otus,"$otus OTUs defined ");
   is($tree->get_name ,$tree_name,"the quoted tree name $tree_name parsed correctly");

# Check the brach length parsing for the tree with branch length in scientific notation
   if ($tree_name =~/scient/) {
      my $node = $tree->find('B');
      ok( defined $node,"Node name 'B' parsed correctly");
 SKIP: {
	  skip "Node not parsed correctly. Hence the branch length checking is skipped", 1 if not defined $node;
	  is(($node->get_length)*1,20,"Branch length (scientific notation) read correctly") if defined $node;
}
   }
}

# testing processing of translate command in trees block

# note that this test could be stronger-- its just testing whether *some* OTU node 
# in the tree has a name that matches a member of the list of true OTU names. 

print "processing files with a 'translate' command in the trees block\n"; 

$file_names = [
	'trees-translate.nex', 
	# 'Human_mt_DNA.nex', # can't do this due to lack of support for options command in char matrix
	'Treebase-chlamy-dna.nex',
	'Bird_Ovomucoids.nex' 
]; 

my $true_otu_names = [
	[ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H' ], 
#	[  '1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '10.', '11.', '12.', '13.', '14.', '15.', '16.', '17.', '18.', '19.', '20.', '21.', '22.', '23.', '24.', '25.', '26.', '27.', '28.', '29.', '30.', '31.', '32.', '33.', '34.', '35.', '36.', '37.', '38.', '39.', '40.', '41.', '42.', '43.', '44.', '45.', '46.', '47.', '48.', '49.', '50.', '51.', '52.', '53.', '54.', '55.', '56.', '57.', '58.', '59.', '60.', '61.', '62.', '63.', '64.', '65.', '66.', '67.', '68.', '69.', '70.', '71.', '72.', '73.', '74.', '75.', '76.', '77.', '78.', '79.', '80.', '81.', '82.', '83.', '84.', '85.', '86.', '87.', '88.', '89.', '90.', '91.', '92.', '93.', '94.', '95.', '96.', '97.', '98.', '99.', '100.', '101.', '102.', '103.', '104.', '105.', '106.', '107.', '108.', '109.', '110.', '111.', '112.', '113.', '114.', '115.', '116.', '117.', '118.', '119.', '120.', '121.', '122.', '123.', '124.', '125.', '126.', '127.', '128.', '129.', '130.', '131.', '132.', '133.', '134.', '135.', 'chimp', 'C_3', 'C_1', 'C_2', 'P_1' ], 
	['Chlamydomonas_allensworthii_Krueger', 'Chlamydomonas_allensworthii_88.10', 'Chlamydomonas_allensworthii_Chile', 'Chlamydomonas_allensworthii_Flam', 'Chlamydomonas_allensworthii_Hon9', 'Chlamydomonas_allensworthii_Hon2', 'Chlamydomonas_allensworthii_LCN', 'Chlamydomonas_allensworthii_LCH',
'Chlamydomonas_allensworthii_LCA', 'Chlamydomonas_allensworthii_266', 'Chlamydomonas_allensworthii_Neb', 'Chlamydomonas_allensworthii_21A', 'Chlamydomonas_allensworthii_Cat', 'Chlamydomonas_reinhardtii_Crein'],
	[ 'Tympanuchus_cupido', 'Oreortyx_pictus', 'Callipepla_squamata_n', 'Callipepla_squamata_s', 'Lophortyx_californicus', 'Colinus_virginianus', 'Cyrtonyx_montezumae_l', 'Cyrtonyx_montezumae_s','Alectoris_chukar','Alectoris_rufa' ]
]; 

my $index; 
my $file_name; 

for ( $index = 0; $index < 3; $index++ ) {
	$file_name = @{$file_names}[$index];
	$file_name = 't/data/compliant/'.$file_name; 
	
	eval {
   		$nexus_obj = new Bio::NEXUS( $file_name );
   		$tree_block = $nexus_obj->get_block('trees');
	};

   is( $@,'', 'TreesBlock object created and parsed');                # check that we got something
   plan skip_all => "Problem reading NEXUS file" if $@;

   $tree = $tree_block->get_tree();
   my $nodes = $tree->get_nodes();
   for my $true_name ( @{ @ {$true_otu_names}[$index] }) {
   		my $found = 0; 
        for my $node (@$nodes) {
        	if ( $node->is_otu() ) {    #check for translation            
            	my $name = $node->get_name();
#            	print "name is $name, true_name is $true_name\n"; 
            	if  ( $name eq $true_name ) { $found = 1; last; } 
            }
        }
        is( $found, 1, "otu name from tree matches true name" ); 
    }
}