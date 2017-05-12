#!/usr/bin/env perl

# construct_dt_for_heavytailed.pl

##  This script illustrates how to set up your DecisionTree constructor call if one
##  or more of the features in your training file has a large dynamic range and is
##  likely to be heavytailed.

use strict;
use warnings;
use Algorithm::DecisionTree;

my $training_datafile = "heavytailed.csv";

#my $training_datafile = "heavyshort.csv";

my $dt = Algorithm::DecisionTree->new( 
                  training_datafile => $training_datafile,
                  csv_class_column_index => 1,
                  csv_columns_for_features => [2,3],
                  entropy_threshold => 0.001,
                  max_depth_desired => 10,
                  symbolic_to_numeric_cardinality_threshold => 10,
                  number_of_histogram_bins => 100,   #<<<<< NOTE THE NEW CONSTRUCTOR OPTION
                  csv_cleanup_needed => 1,
         );

$dt->get_training_data();
$dt->calculate_first_order_probabilities();
$dt->calculate_class_priors();

#   UNCOMMENT THE NEXT STATEMENT if you would like to see the
#   training data that was read from the disk file:
#$dt->show_training_data();

my $root_node = $dt->construct_decision_tree_classifier();

#   UNCOMMENT THE NEXT TWO STATEMENTs if you would like to see the
#   decision tree displayed in your terminal window:
print "\n\nThe Decision Tree:\n\n";
$root_node->display_decision_tree("     ");           
