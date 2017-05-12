#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';


##  find_best_K_in_range_and_cluster.pl


##  IMPORTANT:  Read the 6 point customization of a script like this in the
##              file:
##                            cluster_and_visualize.pl


##  This script is a demonstration of the constructor options:
##
##                    Kmin     and     Kmax
##
##  for a range-bound search for the best K.  Recall K is the number of clusters
##  in your data.


use strict;
use Algorithm::KMeans;

#my $datafile = "mydatafile1.dat";                 # contains 3 clusters, 3D data
my $datafile = "sphericaldata.csv";               # contains 3 clusters, 3D data

my $mask = "N111";
my $clusterer = Algorithm::KMeans->new( datafile         => $datafile,
                                        mask             => "N111",
                                        cluster_seeding  => "random",  # try 'smart' also
                                        Kmin             => 2,
                                        Kmax             => 4,
#                                        use_mahalanobis_metric => 1,   #try '0' also
                                        terminal_output  => 1,
                                        write_clusters_to_files => 1,
                );

$clusterer->read_data_from_file();
my ($clusters_hash, $cluster_centers_hash) = $clusterer->kmeans();

# ACCESSING THE CLUSTERS AND CLUSTER CENTERS IN YOUR SCRIPT:

print "\nDisplaying clusters in the terminal window:\n";
foreach my $cluster_id (sort keys %{$clusters_hash}) {
    print "\n$cluster_id   =>   @{$clusters_hash->{$cluster_id}}\n";
}

print "\nDisplaying cluster centers in the terminal window:\n";
foreach my $cluster_id (sort keys %{$cluster_centers_hash}) {
    print "\n$cluster_id   =>   @{$cluster_centers_hash->{$cluster_id}}\n";
}

# ACCESSING THE BEST VALUE OF K FOUND:

my $K_best = $clusterer->get_K_best();
$clusterer->show_QoC_values();


# VISUALIZATION:

# Visualization mask:
# In most cases, you would not change the value of the mask between clustering and
# visualization.  But, if you are clustering multi-dimensional data and you wish to
# visualize the projection of of the data on each plane separately, you can do so by
# changing the value of the visualization mask.  The number of on bits in the
# visualization must not exceed the number of on bits in the original data mask.
my $visualization_mask = "111";
$clusterer->visualize_clusters($visualization_mask);
