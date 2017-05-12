#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';

##  example2.pl

##  Highlights:
##
##    ---  The data file contains 3000 samples in three large
##         clusters on the surface of a sphere
##
##    ---  Note the use of 0.012 for delta_reconstruction_error


use strict;
use Algorithm::LinearManifoldDataClusterer;

my $datafile = "3_clusters_on_a_sphere_3000_samples.csv";

my $mask = "N111";         # for sphericaldata.csv

my $clusterer = Algorithm::LinearManifoldDataClusterer->new( 
                                    datafile => $datafile,
                                    mask     => $mask,
                                    K        => 3,     # number of clusters
                                    P        => 2,     # manifold dimensionality
                                    max_iterations => 15,
                                    cluster_search_multiplier => 2,
                                    delta_reconstruction_error => 0.012,
                                    terminal_output => 1,
                                    visualize_each_iteration => 1,
                                    show_hidden_in_3D_plots => 0,
                                    make_png_for_each_iteration => 1,
                );

$clusterer->get_data_from_csv();

my $clusters = $clusterer->linear_manifold_clusterer();

$clusterer->display_reconstruction_errors_as_a_function_of_iterations();

$clusterer->write_clusters_to_files($clusters);

$clusterer->visualize_clusters_on_sphere("final_clustering", $clusters);

# Now make a png image file that shows the final clusters:
$clusterer->visualize_clusters_on_sphere("final_clustering", $clusters, "png");

