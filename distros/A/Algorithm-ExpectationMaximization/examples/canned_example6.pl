#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';

### canned_example6.pl

use strict;
use Algorithm::ExpectationMaximization;

my $datafile = "mydatafile7.dat";


my $mask = "N1";    

my $clusterer = Algorithm::ExpectationMaximization->new(
                                datafile            => $datafile,
                                mask                => $mask,
                                K                   => 2,
                                max_em_iterations   => 300,
                                seeding             => 'random',
                                terminal_output     => 1,
                                debug               => 0,
                );

$clusterer->read_data_from_file();

my $data_visualization_mask = "1";
$clusterer->visualize_data($data_visualization_mask);
$clusterer->plot_hardcopy_data($data_visualization_mask);

srand(time);
$clusterer->seed_the_clusters();
$clusterer->EM();
$clusterer->run_bayes_classifier();
$clusterer->write_naive_bayes_clusters_to_files();


my $clusters = $clusterer->return_disjoint_clusters();
# Once you have the clusters in your own top-level script,
# you can now examine the contents of the clusters by the
# following sort of code:
print "\n\nDisjoint clusters obtained with Naive Bayes' classifier:\n\n";
foreach my $index (0..@$clusters-1) {
    print "Cluster $index (Naive Bayes):   @{$clusters->[$index]}\n\n"
}
print "----------------------------------------------------\n\n";

my $theta1 = 0.2;
print "Possibly overlapping clusters based on posterior probabilities " .
    "exceeding the threshold $theta1:\n\n";
my $posterior_prob_clusters =
     $clusterer->return_clusters_with_posterior_probs_above_threshold($theta1);
foreach my $index (0..@$posterior_prob_clusters-1) {
    print "Cluster $index (based on posterior probs exceeding $theta1): " .
          "@{$posterior_prob_clusters->[$index]}\n\n"
}
$clusterer->write_posterior_prob_clusters_above_threshold_to_files($theta1);
print "\n----------------------------------------------------\n\n";

my $theta2 = 0.00001;
print "Showing the data element membership in each Gaussian. Only those " .  
      "data points are included in each Gaussian where the probability " .
      "exceeds the threshold $theta2. Note that the larger the covariance " .
      "and the higher the data dimensionality, the smaller this threshold " .
      "must be for you to see any of the data points in a Gaussian: \n\n";
my $class_distributions =
    $clusterer->return_individual_class_distributions_above_given_threshold($theta2);
foreach my $index (0..@$class_distributions-1) {
    print "Gaussian Distribution $index (only shows data elements whose " .
          "probabilities exceed the threshold $theta2:  " .
          "@{$class_distributions->[$index]}\n\n"
}
print "----------------------------------------------------\n\n";


# VISUALIZATION:

my $visualization_mask = "1"; 

$clusterer->visualize_clusters($visualization_mask);
$clusterer->visualize_distributions($visualization_mask);
$clusterer->plot_hardcopy_clusters($visualization_mask);
$clusterer->plot_hardcopy_distributions($visualization_mask);
$clusterer->display_fisher_quality_vs_iterations();
$clusterer->display_mdl_quality_vs_iterations();
my $estimated_priors = $clusterer->return_estimated_priors();
print "Estimated class priors: @$estimated_priors\n";

