#!/usr/bin/env perl

###   bagging_for_classifying_one_test_sample.pl

##  This script demonstrates how you can use bagging to classify a single test sample.

##  The most important constructor parameters if you want to use bagging:
##
##              how_many_bags
##  and
##
##              bag_overlap_fraction

##  where the meaning of `how_many_bags' is obvious from its name.  The constructor
##  parameter bag_overlap_fraction determines the extent of overlap between the bags.
##  For example, when bag_overlap_fraction is set to 0.20, what that means is that
##  20% additional samples chosen randomly from the other bags will be added to the
##  samples in each bag.  Suppose, the disjoint partition of the training data
##  results in 100 samples in a bag B.  When bag_overlap_fraction is set to 0.20,
##  another 20 samples will be drawn randomly from the the other bags and added to
##  the content of bag B.  After that, the number of samples in bag B will be 120.

use strict;
use warnings;
use Algorithm::DecisionTreeWithBagging;

my $training_datafile = "stage3cancer.csv";

my $dtbag = Algorithm::DecisionTreeWithBagging->new(
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,4,5,6,7,8],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              how_many_bags => 4,
                              bag_overlap_fraction => 0.2,
                              csv_cleanup_needed => 1,
             );

$dtbag->get_training_data_for_bagging();

##   UNCOMMENT the following statement if you want to see the training data placed in each bag:
$dtbag->show_training_data_in_bags();

$dtbag->calculate_first_order_probabilities();

$dtbag->calculate_class_priors();

$dtbag->construct_decision_trees_for_bags();
##   UNCOMMENT the following statement if you want to see the decision tree for each bag:
$dtbag->display_decision_trees_for_bags();

my @test_sample  = qw /  g2=4.2
                         grade=2.3
                         gleason=4
                         eet=1.7
                         age=55.0
                         ploidy=diploid /;

$dtbag->classify_with_bagging( \@test_sample );

##   COMMENT OUT the following statement if you do NOT want to see the classification results
##   produced by each bag:
$dtbag->display_classification_results_for_each_bag();

print "\n\nWill now calculate the majority decision from all bags:\n";
my $decision = $dtbag->get_majority_vote_classification();
print "\nMajority vote decision: $decision\n\n";
