#!/usr/bin/env perl

##   evaluate_training_data2.pl

##  This script is for testing the class discriminatory power of the training data
##  contained in the training files `training.csv', `training2.csv', and
##  `training3.csv'.

##  The three training files mentioned above contain two Gaussian classes with
##  increasing degrees of overlap between them.

##  Through the class EvalTrainingData as shown below, this script runs a 10-fold
##  cross-validation test on the training data.  This test divides all of the
##  training data into ten parts, with nine parts used for training a decision tree
##  and one part used for testing its ability to classify correctly. This selection
##  of nine parts for training and one part for testing is carried out in all of the
##  ten different possible ways.

##  A script like this can also be used to test the appropriateness of your choices
##  for the constructor parameters entropy_threshold, max_depth_desired, and
##  symbolic_to_numeric_cardinality_threshold.

use strict;
use warnings;
use Algorithm::DecisionTree;

my $training_datafile = "training3.csv";

my $eval_data = EvalTrainingData->new( 
                              training_datafile => $training_datafile,
                              csv_class_column_index => 1,
                              csv_columns_for_features => [2,3],
                              entropy_threshold => 0.01,
                              max_depth_desired => 3,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              csv_cleanup_needed => 1,
                );
$eval_data->get_training_data();
$eval_data->evaluate_training_data()

