#!/usr/bin/env perl

##  randomized_trees_for_classifying_one_test_sample_1.pl

##  This script demonstrates using the RandomizedTreesForBigData class for
##  for solving a data classification problem when there is a significant
##  disparity between the populations of the training samples for the
##  the different classes.  You need to set the following two parameters
##  in the call to the constructor for the 'needle-in-a-haystack' logic
##  to work:
##
##              looking_for_needles_in_haystac
##              how_many_trees

use strict;
use warnings;
use Algorithm::RandomizedTreesForBigData;

##  NOTE: The databaes file mentioned below is proprietary and is NOT
##        included in the module package.
#my $training_datafile = "/home/kak/DecisionTree_data/AtRisk/AtRiskModel_File_modified.csv";
#my $training_datafile = "try_50.csv";
my $training_datafile = "try_rand_150.csv";

my $rt = Algorithm::RandomizedTreesForBigData->new(
                              training_datafile => $training_datafile,
                              csv_class_column_index => 48,
                              csv_columns_for_features => [24,32,33,34,41],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              how_many_trees => 5,
                              looking_for_needles_in_haystack => 1,
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
my $test_sample  = ['SATV = 110',
                    'SATM = 130',
                    'SATW = 180',
                    'HSGPA = 1.5'];

print "\nClassify the test sample with each decision tree....\n";
$rt->classify_with_all_trees( $test_sample );

##   COMMENT OUT the following statement if you do NOT want to see the classification results
##   produced by each tree separately:
$rt->display_classification_results_for_all_trees();

print "\n\nWill now calculate the majority decision from all trees:\n";
my $decision = $rt->get_majority_vote_classification();
print "\nMajority vote decision: $decision\n";

