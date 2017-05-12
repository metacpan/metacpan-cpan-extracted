#!/usr/bin/env perl

##  regression5.pl

##  This example script is for demonstrating the power of the regression tree
##  for the case when you have just one predictor variable and one dependent
##  variable.

##  The only difference between this script and regression4.pl is that the
##  data file used here is more complex in terms of how the dependent 
##  variable depends on the predictor variable.

##  Note that I have also increased the value of 'max_depth_desired' to 2
##  in order to deal with the increased complexity in the data.

##  Remember, the column indexing in the csv file is zero-based.  That is,
##  the first column is indexed 0.


use strict;
use warnings;
use Algorithm::RegressionTree;

my $training_datafile = "gendata5.csv";


my $rt = Algorithm::RegressionTree->new( 
                           training_datafile => $training_datafile,
                           dependent_variable_column => 2,
                           predictor_columns => [1],
                           mse_threshold => 0.01,
                           max_depth_desired => 2,
                           jacobian_choice => 0,
                           csv_cleanup_needed => 1,
         );

$rt->get_training_data_for_regression();
my $root_node = $rt->construct_regression_tree();

print "\n\nThe Regression Tree:\n";
$root_node->display_regression_tree("     ");
print "\n\n";

#  Find prediction for just one sample:
my $test_sample = ['xcoord = 128'];
my $answer = $rt->prediction_for_single_data_point($root_node, $test_sample);
printf "Answer returned: %s\n", $answer;
foreach my $kee (keys %$answer) {
    print "$kee    ====>    $answer->{$kee}\n";
}
print "\n\n";
printf "Prediction for test sample: %.9f\n", $answer->{'prediction'};
print "Solution path: @{$answer->{'solution_path'}}\n";

#  Find predictions for all of the predictor data in the training file:
$rt->predictions_for_all_data_used_for_regression_estimation($root_node);
$rt->display_all_plots();
$rt->mse_for_tree_regression_for_all_training_samples($root_node)

