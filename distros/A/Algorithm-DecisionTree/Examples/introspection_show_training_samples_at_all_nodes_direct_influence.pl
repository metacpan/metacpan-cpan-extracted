#!/usr/bin/env perl

##  introspection_show_training_samples_at_all_nodes_direct_influence.pl

##  The purpose of this script is to descend down the decision tree and show
##  at each node the training samples that participated directly in the
##  feature tests leading to that node.  We refer to this as the DIRECT
##  propagation of a training sample's influence to that node.

##  However, in light of the comments made elsewhere in this distribution,
##  note that a training sample can affect nodes indirectly through the
##  generalization achieved by the probabilistic modeling of the data.
##  Examples of this are nodes that are descendants of the nodes affected
##  directly by the training sample.

##      Node 0: the samples are: None
##      Node 1: the samples are: ['sample_46', 'sample_58']
##      Node 2: the samples are: ['sample_1', 'sample_4', 'sample_7', ..... ]
##      Node 3: the samples are: []
##      Node 4: the samples are: []

##  Again, in keeping with the explanation in the main module file, the
##  empty list for the samples at a node indicates merely that the node is
##  a consequence of the generalization achieved by the probabilistic
##  modeling of the training data.

use strict;
use warnings;
use Algorithm::DecisionTree;

my $training_datafile = "stage3cancer.csv";

my $dt = Algorithm::DecisionTree->new( 
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,4,5,6,7,8],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              csv_cleanup_needed => 1,
         );

$dt->get_training_data();
$dt->calculate_first_order_probabilities();
$dt->calculate_class_priors();

#   UNCOMMENT THE NEXT STATEMENT if you would like to see the
#   training data that was read from the disk file:
#$dt->show_training_data();

my $root_node = $dt->construct_decision_tree_classifier();

#   UNCOMMENT THE NEXT TWO STATEMENTS if you would like to see the
#   decision tree displayed in your terminal window:
print "\n\nThe Decision Tree:\n\n";
$root_node->display_decision_tree("     ");           

#   You must construct an instance of the DT introspection class and
#   initialize the instance before you can get any answers through
#   introspection by the instance:
my $introspector = DTIntrospection->new($dt);
$introspector->initialize();

$introspector->display_training_samples_at_all_nodes_direct_influence_only();
