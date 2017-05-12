#!/usr/bin/env perl

##  regression8.pl

##  This script demoknstrates how can carry out bulk prediction for all the
##  test samples in a csv file.

##  IMPORTANT: The topmost record in the CSV file for bulk testing must
##              state the names of the fields.

##  For the example shown below, there is only one predictor variable.
##  This is reflected in the test csv records in the bulk testing file
##
##         bulk_testing_data.csv
##
##  The output results are deposited in the file
##
##         bulk_testing_data_output.csv


use strict;
use warnings;
use Algorithm::RegressionTree;

my $training_datafile = "gendata4.csv";


my $rt = Algorithm::RegressionTree->new( 
                           training_datafile => $training_datafile,
                           dependent_variable_column => 2,
                           predictor_columns => [1],
                           mse_threshold => 0.01,
                           max_depth_desired => 1,
                           csv_cleanup_needed => 1,
         );

$rt->get_training_data_for_regression();
my $root_node = $rt->construct_regression_tree();

print "\n\nThe Regression Tree:\n";
$root_node->display_regression_tree("     ");
print "\n\n";

$rt->bulk_predictions_for_data_in_a_csv_file($root_node, "bulk_testing_data.csv", [1]);

