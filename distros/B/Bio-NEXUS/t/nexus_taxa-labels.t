#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: nexus_taxa-labels.t,v 1.7 2007/09/21 07:30:27 rvos Exp $
# $Revision: 1.7 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

# To test the effect of taxa label strings.

#use Test::More tests => 4;
use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;

use Bio::NEXUS;

my ($nexus, $tree, $tree_block, $taxa_block, $file_name);

################## 1. very long names in various places (OTU, char, tree labels)  #####################################

print "\n---- very long names in various places (OTU, char, tree labels)\n"; 
$file_name = 't/data/compliant/really-long-names.nex';

eval { 
   $nexus      = new Bio::NEXUS( $file_name); 					    # create an object
};

is( $@,'', 'NEXUS object created and parsed');                # check that we got something

$tree_block = $nexus->get_block("trees");
$taxa_block = $nexus->get_block("Taxa");
$tree = $tree_block->get_tree();
is(@{$tree->get_nodes},15,"15 nodes defined: 8 otus + 7 root");
is(@{$tree->get_node_names},8,"8 OTUs defined ");
ok(grep(/OTUWithSpectrophotofluorometricallyPsychoneuroendocrinologicalHepaticocholangiocholecystenterostomiesAlsoHippopotomonstrosesquipedalianSupercalifragilisticexpialidociousAntidisestablishmentarianPseudopseudohypoparathyroidalPneumoencephalographyFromBeyond/, @{$taxa_block->get_taxlabels}) > 0,"Long string properly set in Taxa block");
ok(grep(/SpectrophotofluorometricallyPsychoneuroendocrinologicalHepaticoangiocholecystenterostomiesAndHippopotomonstrosesquipedalianSupercalifragilisticexpialidociousAntidisestablishmentarianPseudopseudohypoparathyroidalPneumoencephalographicCharacterLabelFromHell/, @{$nexus->get_block("Characters")->get_charlabels}) > 0,"Long string properly set in character label in Characters block");
ok(grep(/OTUWithSpectrophotofluorometricallyPsychoneuroendocrinologicalHepaticocholangiocholecystenterostomiesAlsoHippopotomonstrosesquipedalianSupercalifragilisticexpialidociousAntidisestablishmentarianPseudopseudohypoparathyroidalPneumoencephalographyFromBeyond/, @{$nexus->get_block("Trees")->get_tree->get_node_names}) > 0,"Long string properly set in node of the Tree");
is($nexus->get_block("Trees")->get_tree->get_name ,'SupercalifragilisticexpialidociousSpectrophotofluorometricallyPsychoneuroendocrinologicalHepaticocholangiocholecystenterostomiesAndHippopotomonstrosesquipedalianAntidisestablishmentarianPseudopseudohypoparathyroidalPneumoencephalographicPhylogenyFromHell',"Long string properly set in Tree name");

