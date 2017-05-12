#!/usr/bin/env perl

##  introspection_show_training_samples_to_nodes_influence_propagation.pl

##  With this script, you can display how the influence of each training
##  data sample propagates through the decision tree.  The influence
##  propagation is displayed in the following manner:
##
##    sample_1:
##       nodes affected directly: [2, 5, 19, 23]
##       nodes affected through probabilistic generalization:
##            2=> [3, 4, 25]
##                25=> [26]
##            5=> [6]
##                6=> [7, 13]
##                    7=> [8, 11]
##                        8=> [9, 10]
##                        11=> [12]
##                    13=> [14, 18]
##                        14=> [15, 16]
##                            16=> [17]
##            19=> [20]
##                20=> [21, 22]
##            23=> [24]
##    
##    sample_4:
##       nodes affected directly: [2, 5, 6, 7, 11]
##       nodes affected through probabilistic generalization:
##            2=> [3, 4, 25]
##                25=> [26]
##            5=> [19]
##                19=> [20, 23]
##                    20=> [21, 22]
##                    23=> [24]
##            6=> [13]
##                13=> [14, 18]
##                    14=> [15, 16]
##                        16=> [17]
##            7=> [8]
##                8=> [9, 10]
##            11=> [12]
##    
##    ...
##    ...
##
##
##  In the display shown above, the influence of the training sample
##  labeled `sample_1' is felt directly at the nodes labeled 2, 5, 19, and
##  23.  What that means is that the feature tests that result in these
##  nodes coming into existence directly involve the data provided by
##  `sample_1'.  The same training sample also contributes to the formation
##  of the nodes that are the child nodes of those nodes that are affected
##  directly by `sample_1'.  That is, since the nodes 3, 4, and 25 are the
##  child nodes of node 2, they are also indirectly affected by the data
##  provided by `sample1'.  

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

$introspector->display_training_samples_to_nodes_influence_propagation();


