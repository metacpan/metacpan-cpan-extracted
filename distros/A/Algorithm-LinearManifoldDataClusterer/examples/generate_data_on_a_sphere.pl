#!/usr/bin/perl -w

## generate_data_on_a_sphere.pl

use lib '../blib/lib', '../blib/arch';


##    The purpose of this script is to generate multivariate Gaussian data
##    on a spherical surface and, subsequently, to also visualize this
##    data.  Read the comment block attached to the subroutine
##    `gen_data_and_write_to_csv() in the main module file.  That
##    subroutine randomly chooses a number of directions equal to the value
##    of the number_of_clusters_on_sphere.  It also put together 2x2
##    covariance matrices for each of these clusters.  Subsquently, the
##    Random module is called to yield multivariates samples for each
##    cluster on the sphere.


use strict;
use Algorithm::LinearManifoldDataClusterer;

my $output_file = "5_clusters_on_a_sphere_1000_samples.csv";

my $training_data_gen = DataGenerator->new( 
                         output_file => $output_file,
                         cluster_width => 0.0005,
                         total_number_of_samples_needed => 1000,
                         number_of_clusters_on_sphere => 5,
                         show_hidden_in_3D_plots => 0,
                        );

$training_data_gen->gen_data_and_write_to_csv();

$training_data_gen->visualize_data_on_sphere($output_file);


