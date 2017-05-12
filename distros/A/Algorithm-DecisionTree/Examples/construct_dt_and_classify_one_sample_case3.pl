#!/usr/bin/env perl

##  construct_dt_and_classify_one_sample_case3.pl

##  This script does the same thing as the script
##  construct_dt_and_classify_one_sample_case2.pl except that it uses just two of the
##  columns of the csv file for DT construction and classification.  The two features
##  used are in columns indexed 3 and 5 of the csv file.

##  Remember that column indexing is zero-based in the csv file.

use strict;
use warnings;
use Algorithm::DecisionTree;

my $training_datafile = "stage3cancer.csv";

my $dt = Algorithm::DecisionTree->new( 
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,5],
                              entropy_threshold => 0.01,
                              max_depth_desired => 4,
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

#   UNCOMMENT THE NEXT TWO STATEMENTs if you would like to see the
#   decision tree displayed in your terminal window:
print "\n\nThe Decision Tree:\n\n";
$root_node->display_decision_tree("     ");           

my @test_sample  = qw /  g2=20
                         age=80.0 /;

#   The classifiy() in the call below returns a reference to a hash
#   whose keys are the class labels and the values the associated 
#   probabilities:
my %classification = %{$dt->classify($root_node, \@test_sample)};

my @solution_path = @{$classification{'solution_path'}};
delete $classification{'solution_path'};
my @which_classes = keys %classification;

@which_classes = sort {$classification{$b} <=> $classification{$a}} 
                                                     @which_classes;
print "\nClassification:\n\n";
print "     class                         probability\n";
print "     ----------                    -----------\n";
foreach my $which_class (@which_classes) {
    my $classstring = sprintf("%-30s", $which_class);
    my $valuestring = sprintf("%-30s", $classification{$which_class});
    print "     $classstring $valuestring\n";

}
print "\nSolution path in the decision tree: @solution_path\n";
print "\nNumber of nodes created: " . $root_node->how_many_nodes() . "\n";

