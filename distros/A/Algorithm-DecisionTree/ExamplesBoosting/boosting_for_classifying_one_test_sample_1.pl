#!/usr/bin/env perl

###   boosting_for_classifying_one_test_sample_1.pl

##  This script demonstrates how you can use boosting to classify a single
##  test sample.

##  The most important thing to keep in mind if you want to use boosting is
##  the constructor parameters:
##
##              how_many_stages

##  As its name implies, this parameter controls how many decision trees
##  will cascaded together for the boosted classifier.  Recall that the
##  training set for each decision tree in a cascade is heavily influenced
##  by what gets misclassified by the previous decision tree.  At the same
##  time, the trust we place in each decision tree is based on its overall
##  performance for classifying the entire training dataset.


use strict;
use warnings;
use Algorithm::BoostedDecisionTree;

my $training_datafile = "stage3cancer.csv";

my $boosted = Algorithm::BoostedDecisionTree->new(
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,4,5,6,7,8],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              how_many_stages => 4,
                              csv_cleanup_needed => 1,
             );

print "Reading and processing training data...\n";
$boosted->get_training_data_for_base_tree();

##   UNCOMMENT THE FOLLOWING STATEMENT if you want to see the training data used for
##   just the base tree:
$boosted->show_training_data_for_base_tree();

# This is a required call:
print "Calculating first-order probabilities...\n";
$boosted->calculate_first_order_probabilities_and_class_priors();

# This is a required call:
print "Constructing base decision tree...\n";
$boosted->construct_base_decision_tree();

#   UNCOMMENT THE FOLLOWING TWO STATEMENTS if you would like to see the base decision
#   tree displayed in your terminal window:
#print "\n\nThe Decision Tree:\n\n";
#$boosted->display_base_decision_tree();

# This is a required call:
print "Constructing the rest of the decision trees....\n";
$boosted->construct_cascade_of_trees();

#  UNCOMMENT the following statement if you wish to see the class labels for the
#  samples misclassified by any particular stage.  The integer argument in the call
#  you see below is the stage index.  Whe set to 0, that means the base classifier.
$boosted->show_class_labels_for_misclassified_samples_in_stage(0);


##  UNCOMMENT the next statement if you want to see the decision trees constructed
##  for each stage of the cascade:
print "\nDisplaying the decision trees for all stages:\n\n";
$boosted->display_decision_trees_for_different_stages();

print "Reading the test sample ...\n";
my $test_sample  = ['g2 = 4.2',
                    'grade = 2.3',
                    'gleason = 4',
                    'eet = 1.7',
                    'age = 55.0',
                    'ploidy = diploid'];

# This is a required call:
print "Classifying with all the decision trees ....\n";
$boosted->classify_with_boosting($test_sample);

#   UNCOMMENT THE FOLLOWING TWO STATEMENTS if you would like to see the classification
#   results obtained with all the decision trees in the cascade:
print "\nDisplaying the classification results with all stages:\n\n";
$boosted->display_classification_results_for_each_stage();

my $final_classification = $boosted->trust_weighted_majority_vote_classifier();

print "\nFinal classification: $final_classification\n";

$boosted->display_trust_weighted_decision_for_test_sample();

