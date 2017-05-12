#!/usr/bin/perl 


######################################################################
# nex2text_tree.pl -- Visulation of tree as strings
######################################################################
#
# $Author: thladish $
# $Date: 2006/08/24 06:41:57 $
# $Revision: 1.7 $
# $Id: nexplot.pl,v 1.33 2006/05/17 21:45:52 thladish Exp

use strict;

use Data::Dumper;
use Bio::NEXUS;

use Getopt::Long;
use Pod::Usage;


## INPUT PARAMETERS
my $verticalOtuSpacing = 4; # Even number increments are better for the binary trees
my $lowerYbound        = 0;
my $lowerXbound        = 5;
my $treeWidth          = 30;
my $cladogram_type     = 0; # 0 or 'normal' or 'accelerated'


### Options parsing and processing using Getopts###

my %h;

my $opt_result;

local $SIG{__WARN__} = sub { die $_[0] }; ## Warning signal to die signal for capturing by warnings by 'eval' function
eval {
   GetOptions (\%h, 'manual|m', 'help|h', 'demo', 'tree_width|w=i','otu_spacing|s=i', 'input|i=s','output|o=s', 'version|V','verbose','cladogram|c=s');
};

if ($@ ne '') {
   die "Options parsing error : $@-- use \'perl nex2text_tree.pl --help\' for correct options\n";
}

if ($h{'cladogram'}) {
die ( "Only 'normal', 'accelerated' options supported : see \'perl nex2text_tree.pl --help\' for correct options \n" ) if not ($h{'cladogram'} =~/accelerated/i or $h{'cladogram'} =~/normal/i);
$cladogram_type = lc($h{'cladogram'});
}
local $SIG{__WARN__} = sub { warn $_[0] }; ## turning back warning signal

if ( exists $h{tree_width} ) { $treeWidth = $h{'tree_width'}}
if ( exists $h{otu_spacing} ) { $verticalOtuSpacing = $h{'otu_spacing'}}

pod2usage(1) if $h{'help'};
pod2usage(-exitstatus => 0, -verbose => 2) if $h{man};
die '$Id: nex2text_tree.pl,v 1.7 2006/08/24 06:41:57 thladish Exp $',"\n" if ( $h{ 'V' } ); 
die "Dataset not provided : Input file option(--input) or demo option (--demo) must be specified.\n" if ((not exists($h{input})) and (not exists ($h{demo})));

my $input_file   = $h{'input'};
my $output_file  = $h{'output'};
my $out_file_h;

print "#" x 50,"\n" if $h{'verbose'};

open (INP, $input_file) || die "Cannot open input file : $input_file\n" if (not $h{demo});
if ($output_file) {
   open (OUT, ">$output_file") || die "Cannot open output file for writing : $output_file\n";
   $out_file_h = \*OUT;
   print "Output filename :$out_file_h\n" if $h{'verbose'};
}else {
   $out_file_h = \*STDOUT;
}

##OTHER VARIABLEs
my $maxNodeWidth   = 0; # maximum node with used for calculating the X bound of the plot
my $treeHeight     = 0;  
my $upperYbound    = 0;
my $upperXbound    = 0;
my $tree_string;      # Contains the tree as string ( upperXbound by upperYbound matrix)

my $tree;

### Obtaining the Tree object to be converted to text.

if ($h{'demo'}) {
## Demo datasets
#TREE con_50_majrule = (Arabidopsis_thaliana_CAA42069.1:0.135290,Rosellinia_necatrix_BAC54258.1:0.129096,(Fusarium_oxysporum_BAA85768.1:0.088840,((Emericella_nidulans_AAB50255.1:0.197013,((((Debaryomyces_occidentalis_CAA37787.1:0.046199,Pichia_stipitis_AAB86817.3:0.052188)inode8:0.040288[0.96],Candida_albicans_AAB68996.1:0.031209)inode7:0.025670[0.82],((Kluyveromyces_lactis_CAA43224.1:0.070408,((Saccharomyces_cerevisiae_CAA89576.1:0.047955,Saccharomyces_cerevisiae_AAB65003.1:0.137095)inode12:0.047348[0.67],Candida_glabrata_CAA41203.1:0.083197)inode11:0.099385[1.00])inode10:0.052048[0.63],Pachysolen_tannophilus_AAD02430.1:0.101883)inode9:0.043340[0.61])inode6:0.136023[1.00],Schizosaccharomyces_pombe_CAB41053.1:0.144540)inode5:0.080044[0.90])inode4:0.067075[0.70],(((((((Tigriopus_californicus_AAC80533.1:0.008887,Tigriopus_californicus_AAC80535.1:0.018489,Tigriopus_californicus_AAC80537.1:0.017438)inode19:0.023821[0.71],(Tigriopus_californicus_AAC80553.1:0.024848,Tigriopus_californicus_AAC80552.1:0.009379)inode20:0.027883[0.82])inode18:0.134497[0.97],Drosophila_melanogaster_AAF53553.1:0.207983,(((Chaetoceros_gracilis_BAC54099.1:0.119229,(Chlorella_vulgaris_BAC76447.1:0.315427,Chlorella_vulgaris_BAC76448.1:0.323294,Chlamydomonas_reinhardtii_AAB00729.1:0.303235)inode24:0.335171[1.00])inode23:0.160784[0.76],Phaeodactylum_tricornutum_AAO43197.1:0.089007)inode22:0.913134[1.00],Arabidopsis_thaliana_BAB10887.1:1.406471)inode21:1.038263[0.99])inode17:0.079735[0.59],((Mus_musculus_CAA25899.1:0.008307,Rattus_norvegicus_AAA21711.1:0.009662)inode26:0.024280[0.74],(Gallus_gallus_CAA25046.1:0.055226,Rattus_norvegicus_AAA41015.1:0.117358)inode27:0.040335[0.69])inode25:0.052721[0.84])inode16:0.075053[0.63],Drosophila_melanogaster_AAF53554.1:0.069168)inode15:0.079006[0.67],(((((Arabidopsis_thaliana_AAB72175.1:0.064459,Arabidopsis_thaliana_CAB78127.1:0.023524)inode32:0.064349[0.92],Oryza_sativa_AAA63515.1:0.038470)inode31:0.060944[0.86],Oryza_sativa_BAB90158.1:0.225540)inode30:0.137772[0.99],Chlamydomonas_reinhardtii_CAB16954.1:0.152376)inode29:0.152746[0.99],((Caenorhabditis_elegans_CAA98555.1:0.177383,Caenorhabditis_elegans_AAB92035.1:0.058081)inode34:0.326057[0.98],Plasmodium_falciparum_AAN36650.1:0.301053)inode33:0.094984[0.71])inode28:0.091560[0.91])inode14:0.106401[0.56],Dictyostelium_discoideum_AAO53091.1:0.414927)inode13:0.105943[0.79])inode3:0.087158[0.96])inode2:0.069976[0.98])root;
#TREE Tree = (Plasmodium_falciparum_16805076:1.800,(Arabidopsis_thaliana_18399137:1.642,((Schizosaccharomyces_pombe_19115679:0.837,Saccharomyces_cerevisiae_6323318:0.837)inode3:0.705,(Caenorhabditis_elegans_17563246:1.220,(Homo_sapiens_4503659:1.063,(Anopheles_gambiae_agCT48044:0.250,Drosophila_melanogaster_7300667:0.250)inode6:0.813)inode5:0.157)inode4:0.322)inode2:0.100)inode1:0.158)root:.2;
my $tr=<<STRING;
BEGIN TREES;
TREE Tree = (Plasmodium_falciparum_16805076:1.800,(Arabidopsis_thaliana_18399137:1.642,((Schizosaccharomyces_pombe_19115679:0.837,Saccharomyces_cerevisiae_6323318:0.837)inode3:0.705,(Caenorhabditis_elegans_17563246:1.220,(Homo_sapiens_4503659:1.063,(Anopheles_gambiae_agCT48044:0.250,Drosophila_melanogaster_7300667:0.250)inode6:0.813)inode5:0.157)inode4:0.322)inode2:0.100)inode1:0.158)root:.2;
END;
STRING

# TreesBlock object creation
my $tree_b = new Bio::NEXUS::TreesBlock;
$tree_b->parse_block($tr);
$tree = $tree_b->get_tree;
} else {

   my $nexus = new Bio::NEXUS($input_file);
   $tree = $nexus->get_block("Trees")->get_tree;
}

### Processing of the Tree

my $root = $tree->get_rootnode;


# Setting x and y coordiates for all the nodes based on the Tree
$tree->_set_xcoord($treeWidth,$cladogram_type);
$tree->_set_ycoord($lowerYbound,$verticalOtuSpacing);
my @nodes = @{$tree->node_list()};

print "Width of Tree    : ", $treeWidth,"\n" if $h{'verbose'};
print "Vertical spacing : ", $verticalOtuSpacing,"\n" if $h{'verbose'};
print "Name of tree     : ", $tree->name,"\n" if $h{'verbose'};
print "No. of nodes     : ", $#nodes +1,"\n" if $h{'verbose'};
print "No. of OTUs      : ", scalar @{$tree->otu_list},"\n" if $h{'verbose'};
print "Newick Format   \n", $tree->as_string,"\n\n" if $h{'verbose'};
print "#" x 50,"\n\n" if $h{'verbose'};

my @sorted;
for my $node (@nodes) {
   push @sorted, $node->xcoord();
}
@sorted = sort { $a <=> $b } @sorted;

my $amp = $treeWidth / pop @sorted; # unit of branch length
for my $node (@nodes) {
   $node->_set_xcoord( $lowerXbound + ($node->xcoord() * $amp) );
}

# Setting x and y bounds for the plot
&__find_treemax($root);
$upperYbound = $treeHeight + 5;
$upperXbound = $treeWidth + $maxNodeWidth;
for(my $i = 0; $i < int($upperYbound) ; $i++) {
   $tree_string->[$i] = [split(/1/,' 1' x $upperXbound)];
   #print $#{$tree_string->[$i]} , "\n";
}
#print "Tree height - $treeHeight  Tree width - $treeWidth\n\n";
&__print_tree($root,$lowerXbound,$lowerYbound);

## Printing the tree to the output
for(my $i = 0; $i < int($upperYbound) ; $i++) { ## No of rows (height)
   print $out_file_h join '', @{$tree_string->[$i]} , "\n";
}

close OUT;
close INP;
###### End of the program


#   + ------------------ Pl
#   |    +---------- Ar
# --|    |
#   |----|
#   |    +------------- Sc


sub __print_tree {
   my ($node, $x0, $y0) = @_;
   my $name = $node->name();
   my $is_otu = $node->is_otu;
   my $x1 = int ($node->xcoord);
   my $y1 = int ($node->ycoord);

   my $i;
   my $j;
   my $delta;
   #print " $name x0=$x0 y0=$y0  -- x1=$x1  y1=$y1 \n";
   $i = $x1 - $x0;
   $delta =  ($i > 0 ) ? 1 : -1;
   until ($i == 0 ) {  # Horizontal lines
      $j = $x0 + $i;
      if ($j==$x1 and (not $is_otu)) {
	 $$tree_string[$y1][$j] = "+";
      }else {
	 $$tree_string[$y1][$j] = "-";
      }
      #print " horizontal - j=$j,y0=$y0 \n";
      $i = $i - $delta;
   } # end of until

   unless ($node->name eq 'root') {
      $i = $y1 - $y0;
      $delta =  ($i >= 0 ) ? 1 : -1;
      until ($i == 0 ) { 	# Vertical lines of the tree ( only for the non-root nodes)
	 $j = $y0 + $i;
	 if ($j==$y1) {
	    #$$tree_string[$j][$x0] = ($delta > 0) ? "\\" : "/";
	    $$tree_string[$j][$x0] = "+";
	 }else {
	    $$tree_string[$j][$x0] = "|";
	 }
	 #print " vertical -i=$i x0=$x0,j=$j \n";
	 $i = $i - $delta;
      } #end of until
   } # end of unless

   if ($node->is_otu()) {
      $$tree_string[$y1][$x1 + 2] = $name;
   }else {
      #  $$tree_string[$y1][$x1] = $name;
   }
   if (not $node->is_otu) {
      foreach my $child (@{$node->children()} ) {
	 &__print_tree($child, $x1, $y1);
      }
   }
}

# Finds the maximum x and y ranges of the tree (Obtained from nexplot.pl)
sub __find_treemax {
   my $node = shift;
   my $name = $node->name();
   my $x1 = int ($node->xcoord);
   my $y1 = int ($node->ycoord);
   if ($node->is_otu()) {
      my ($x, $y) = ($x1 + 7.5, $y1);         # For each item, computes branch length with name and compares to highest known value

      $treeHeight=$y if ($y > $treeHeight);
      $maxNodeWidth=length($name) if ($maxNodeWidth < length($name));

   }
   if (not $node->is_otu) {
      foreach my $child (@{$node->children()} ) {
	 &__find_treemax($child);
      }
   }
}

# Picks first OTU and finds treemax plus character length, that is,
# the x range of the entire plot (Obtained from nexplot.pl)
sub __find_xbound {
   my ($node) = @_;
   my $name = $node->name();
   my $x1 = int ($node->xcoord);
   my $y1 = int ($node->ycoord);
   if (not $node->is_otu()) {
      foreach my $child (@{$node->children()} ) {
	 return 1 if &__find_xbound($child, $x1, $y1);
      }
      return 0;
   }
   my ($x, $y) = ($x1 + 7.5, $y1 - 2.5);
   return 0;
}

__DATA__

=pod 

=head1 NAME

nex2text_tree.pl - Trees as strings

=head1 SYNOPSIS

 nex2text_tree.pl [options] [file ...]
 nex2text_tree.pl --tree_width 100 --otu_spacing 4 --demo
 nex2text_tree.pl -i input.nex -o text_string_tree.out --tree_width 100 --otu_spacing 4


=head1 OPTIONS

    -d or --demo       	            Prints out a default tree to the STDOUT
    -h or --help      	            Brief help message about the options
    -m or --manual     	            Full documentation
    -i or --input <file_name>       Specify input NEXUS file 
    -o or --output <file_name>      Specify output file (default: STDOUT)
    -w or --tree_width 30           Total width of the output tree string (default = 30) [Integer]
    -s or --otu_spacing 4           Vertical spacing betweein OTUs (default value = 4) [Integer]
    -V or --version                 Print version information and quit
    --verbose                       The parameters are also printed along with the tree.
    -c or --cladogram  normal       The parameters are also printed along with the tree. (options: 'normal' or 'accelarated')


=head1 DESCRIPTION

   B<nex2text_tree.pl> prgram will read the given input NEXUS file and converts the newick tree in the TreesBlock 
   as string.

=head1 AUTHOR(S)

	  Vivek Gopalan (gopalan_vivek@yahoo.com)	   

=head1 METHODS

=cut
