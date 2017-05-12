#!/usr/bin/env perl

##  regression6.pl

##  This script shows the power of tree regression involving 3D data.  We now have
##  TWO predictor variables and one dependent variable.

##  Remember, the column indexing in the csv file is zero-based.  That is,
##  the first column is indexed 0.

use strict;
use warnings;
use Algorithm::RegressionTree;

my $training_datafile = "gen3Ddata1.csv";

my $rt = Algorithm::RegressionTree->new( 
                           training_datafile => $training_datafile,
                           dependent_variable_column => 3,
                           predictor_columns => [1,2],
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
my $test_sample = ['x1_coord = 50', 'x2_coord = 50'];
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


