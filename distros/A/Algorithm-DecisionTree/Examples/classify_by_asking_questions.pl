#!/usr/bin/env perl

## classify_by_asking_questions.pl

use strict;
use warnings;
use Algorithm::DecisionTree;

#my $training_datafile = "training.dat";
my $training_datafile = "stage3cancer.csv";

my $dt = Algorithm::DecisionTree->new( 
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,4,5,6,7,8],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              csv_cleanup_needed => 1,
         );

$dt->get_training_data();
$dt->calculate_first_order_probabilities();
$dt->calculate_class_priors();

### UNCOMMENT THE NEXT STATEMENT if you would like to see
### the training data that was read from the disk file:
#$dt->show_training_data();

#print "\nStarting construction of the decision tree:\n\n";
my $root_node = $dt->construct_decision_tree_classifier();

###   UNCOMMENT THE NEXT STATEMENT if you would like to see
###   the decision tree displayed in your terminal window:
$root_node->display_decision_tree("     ");           

### The classifiy() in the call below returns a reference to
### a hash whose keys are the class labels and the values
### the associated probabilities:

my %classification = %{$dt->classify_by_asking_questions($root_node)};

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

