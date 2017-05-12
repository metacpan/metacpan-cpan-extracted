#!/usr/bin/env perl

##  introspection_in_a_loop_interactive.pl

##  This script puts you in an infinite loop in which you can ask the
##  DTIntrospection class of the module to provide you with information
##  regarding the different nodes of the decision tree. 

##  Perhaps the most important bit of information you are likely to seek
##  through DT introspection is the list of the training samples that fall
##  directly in the portion of the feature space that is assigned to a
##  node.  

##  However, note that, when training samples are non-uniformly distributed
##  in the underlying feature space, it is possible for a node to exist
##  even when there are no training samples in the portion of the feature
##  space assigned to the node.  That is because the decision tree is
##  constructed from the probability densities estimated from the training
##  data.  When the training samples are non-uniformly distributed, it is
##  entirely possible for the estimated probability densities to be
##  non-zero in a small region around a point even when there are no
##  training samples specifically in that region.  (After you have created
##  a statistical model for, say, the height distribution of people in a
##  community, the model may return a non-zero probability for the height
##  values in a small interval even if the community does not include a
##  single individual whose height falls in that interval.)

##  That a decision-tree node can exist even where there are no training
##  samples in the feature space is an important indication of the
##  generalization abilities of a decision-tree-based classifier.

##  VERY IMPORTANT:

##  In light of the explanation provided above, before the DTIntrospection
##  class supplies any answers at all, it asks you to accept the fact that
##  features can take on non-zero probabilities at a point in the feature
##  space even though there are zero training samples at that point (or in
##  a small region around that point).  If you do not accept this
##  rudimentary fact, the introspection class will not yield any answers
##  (since you are not going to believe the answers anyway).

##  The point made above implies that the path leading to a node in the
##  decision tree may test a feature for a certain value or threshold
##  despite the fact that the portion of the feature space assigned to that
##  node is devoid of any training data.

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

#   The following call will put you in an interactive session in which you
#   will be asked for the node numbers you are interested in.  At each
#   node, you will be asked for whether or not you are interested in
#   specific questions that the introspector can provide answers for.
$introspector->explain_classifications_at_multiple_nodes_interactively();
