#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';


##  example1.pl

##  Highlights:
##
##    ---  The main highlight here is the use of the auto_retry_clusterer()
##         method for automatically invoking the clusterer repeatedly 
##         should it fail on account of the Fail-First bias built into
##         the code.
##
##    ---  The data file contains 498 samples in three small clusters 
##         on the surface of a sphere
##
##    ---  Note the use of 0.001 for delta_reconstruction_error

use strict;
use Algorithm::LinearManifoldDataClusterer;


my $datafile = "3_clusters_on_a_sphere_498_samples.csv";

my $mask = "N111"; 

my $clusterer = Algorithm::LinearManifoldDataClusterer->new( 
                                    datafile => $datafile,
                                    mask     => $mask,
                                    K        => 3,     # number of clusters
                                    P        => 2,     # manifold dimensionality
                                    max_iterations => 15,
                                    cluster_search_multiplier => 1,
                                    delta_reconstruction_error => 0.001,
                                    terminal_output => 1,
                                    visualize_each_iteration => 1,
                                    show_hidden_in_3D_plots => 1,
                                    make_png_for_each_iteration => 1,
                );

$clusterer->get_data_from_csv();

my $clusters = $clusterer->auto_retry_clusterer();

$clusterer->display_reconstruction_errors_as_a_function_of_iterations();

$clusterer->write_clusters_to_files($clusters);

$clusterer->visualize_clusters_on_sphere("final clustering", $clusters);

# Now make a png image file that shows the final clusters:
$clusterer->visualize_clusters_on_sphere("final_clustering", $clusters, "png");
