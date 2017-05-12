#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';

##  cluster_after_data_normalization.pl

##  IMPORTANT:  Read the 6 point customization of a script like this in the file:
##
##                            cluster_and_visualize.pl


##  This script demonstrates the use of the 
##
##                do_variance_normalization
##
##  in the constructor.  This option normalizes the data variances along all the data
##  dimensions before clustering.  As explained in the main documentation, this may
##  or may not improve the quality of the results.


use strict;
use Algorithm::KMeans;

#my $datafile = "mydatafile1.dat";           # contains 3 clusters, 3D data
my $datafile = "sphericaldata.csv";           # contains 3 clusters, 3D data

my $mask = "N111";

my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                        mask     => $mask,
                                        cluster_seeding  => "random",  # try 'smart' also
                                        K        => 3,
                                        terminal_output => 1,
                                        do_variance_normalization => 1,
#                                        use_mahalanobis_metric => 1,   # try 0 also
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

# CLUSTER VISUALIZATION:

# See the comment block in cluster_and_vsualize.pl for how to set up the mask and
# what it means.
my $visualization_mask = "111";
$clusterer->visualize_clusters($visualization_mask);

