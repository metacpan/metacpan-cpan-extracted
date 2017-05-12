#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';


##  which_cluster_for_new_data.pl

##  Let's say that after you are done with the clustering of your data, you have a
##  new data element and you want to find out as to which cluster it belongs to.
##  This script demonstrates how you can do that by making calls to the following
##  two methods of the module:
##
##        which_cluster_for_new_data_element()
##
##        which_cluster_for_new_data_element_mahalanobis()
##
##  Both these methods do the same thing except that that latter uses the 
##  Mahalanobis metric to measure the distance between the new data element
##  and each of the clusters.

use strict;
use Algorithm::KMeans;


my $datafile = "mydatafile1.dat";                # contains 3 clusters, 3D data
#my $datafile = "mydatafile3.dat";                # contains 2 clusters, 2D data

my $mask = "N111";        # for mydatafile1.dat --- use all three data cols
#my $mask = "N11";         # for mydatafile3.dat


my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                        mask     => $mask,
                                        K        => 3,
                                        cluster_seeding => 'random',   # also try 'smart'
                                        use_mahalanobis_metric => 1,   # also try '0'
                                        terminal_output => 1,
                                        write_clusters_to_files => 1,
                                        debug => 0,
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


# FIND CLUSTER IDENTITY OF A NEW DATA RECORD:

my $new_datum = [20,4,0];                  # for mydatafile1.dat
#my $new_datum = [20,4];                    # for mydatafile3.dat
my $cluster_name = $clusterer->which_cluster_for_new_data_element($new_datum);
print "\nUsing Euclidean distances: The data element @$new_datum belongs to cluster: $cluster_name\n";

my $cluster_name2 = 
            $clusterer->which_cluster_for_new_data_element_mahalanobis($new_datum);
print "\nUsing Mahalanobis distances: The data element @$new_datum belongs to cluster: $cluster_name2\n";



# VISUALIZATION:

my $visualization_mask = "111";    # for mydatafile1.dat with all 3 data cols
#my $visualization_mask = "11";     # for mydatafile3.dat

$clusterer->visualize_clusters($visualization_mask);

