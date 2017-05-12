#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';

##  example3.pl

##  Highlights:
##
##    --- The data file contains 1000 samples in four small
##        clusters on the surface of a sphere
##
##    ---  Note the use of 0.002 for delta_reconstruction_error


use strict;
use Algorithm::LinearManifoldDataClusterer;

my $datafile = "4_clusters_on_a_sphere_1000_samples.csv";

my $mask = "N111";         # for sphericaldata.csv

my $clusterer = Algorithm::LinearManifoldDataClusterer->new( 
                                    datafile => $datafile,
                                    mask     => $mask,
                                    K        => 4,     # number of clusters
                                    P        => 2,     # manifold dimensionality
                                    cluster_search_multiplier => 2,
                                    max_iterations => 15,
                                    delta_reconstruction_error => 0.002,
                                    terminal_output => 1,
                                    visualize_each_iteration => 1,
                                    show_hidden_in_3D_plots => 1,
                                    make_png_for_each_iteration => 1,
                );

$clusterer->get_data_from_csv();

my $clusters = $clusterer->linear_manifold_clusterer();

$clusterer->display_reconstruction_errors_as_a_function_of_iterations();

$clusterer->write_clusters_to_files($clusters);

$clusterer->visualize_clusters_on_sphere("final clustering", $clusters);

# Now make a png image file that shows the final clusters:
$clusterer->visualize_clusters_on_sphere("final_clustering", $clusters, "png");
