#!/usr/bin/env perl

##  randomized_trees_for_classifying_one_test_sample_2.pl

##  This script demonstrates how you can use the RandomizedTreesForBigData
##  class for data classification in the big data context.  Assuming you
##  have access to a very large training database, you can draw multiple
##  random datasets from the database and use each for constructing a
##  different decision tree.  Subsequently, the final classification for a
##  new data sample can be based on majority voting by all the decision
##  trees thus constructed.  In order to use this functionality, you need
##  to set the following two constructor parameters of this class:
##
##           how_many_training_samples_per_tree
##
##           how_many_trees


use strict;
use warnings;
use Algorithm::RandomizedTreesForBigData;

my $training_datafile = "stage3cancer.csv";

my $rt = Algorithm::RandomizedTreesForBigData->new(
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,4,5,6,7,8],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              how_many_trees => 3,
                              how_many_training_samples_per_tree => 50,
                              csv_cleanup_needed => 1,
         );

print "\nReading the training data ...\n";
$rt->get_training_data_for_N_trees();

##   UNCOMMENT the following statement if you want to see the training data used for each tree::
$rt->show_training_data_for_all_trees();


print "\nCalculating first order probabilities...\n";
$rt->calculate_first_order_probabilities();

print "\nCalculating class priors...\n";
$rt->calculate_class_priors();

print "\nConstructing all decision trees ....\n";
$rt->construct_all_decision_trees();

##   UNCOMMENT the following statement if you want to see all decision trees individually:
$rt->display_all_decision_trees();

print "\nReading the test sample....\n";
my $test_sample  = ['g2 = 4.2',
                    'grade = 2.3',
                    'gleason = 4',
                    'eet = 1.7',
                    'age = 55.0',
                    'ploidy = diploid'];

print "\nClassify the test sample with each decision tree....\n";
$rt->classify_with_all_trees( $test_sample );

##   COMMENT OUT the following statement if you do NOT want to see the classification results
##   produced by each tree separately:
$rt->display_classification_results_for_all_trees();

print "\n\nWill now calculate the majority decision from all trees:\n";
my $decision = $rt->get_majority_vote_classification();
print "\nMajority vote decision: $decision\n";

