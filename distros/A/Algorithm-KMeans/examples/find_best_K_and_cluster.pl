#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';

##  find_best_K_and_cluster.pl


##  IMPORTANT:  Read the 6 point customization of a script like this in the file:
##
##                       cluster_and_visualize.pl



##  This script is a demonstration of the constructor option:
##
##                           K => 0
##
##  for an unbounded search for the best K --- unbounded to the extent permitted by
##  the number of data records in your data file.  Recall K is the number of clusters
##  in your data.  By its very nature, unbounded search for the best K could take
##  more time than you have patience for if your data file is large.  In such cases,
##  you could try range bounded search as in the script: 
##
##                    find_best_K_in_range_and_cluster.pl




use strict;
use Algorithm::KMeans;

my $datafile = "mydatafile1.dat";                  # contains 3 clusters, 3D data
#my $datafile = "mydatafile2.dat";                   # contains 2 clusters, 3D data

# Mask:

# The mask tells the module which columns of the data file are are to be used for
# clustering, which columns are to be ignored and which column contains the symbolic
# ID tag for a data point.  If the ID is in the first column and you are clustering
# 3D data in the next three columns, the mask would be "N111".  Note the first
# character in the mask in this case is `N' for "Name".  If, on the other hand, you
# wanted to ignore the first data coordinate for clustering, the mask would be
# "N011".  The symbolic ID can be in any column --- you just have to place the
# character `N' at the right place:

my $mask = "N111";
#my $mask = "N11";

my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                        mask     => $mask,
                                        K        => 0,
                                        cluster_seeding => 'random',   # try 'smart' also
#                                        use_mahalanobis_metric => 1,   # try '0' also
                                        write_clusters_to_files => 1,
                                        terminal_output => 1,
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

my $visualization_mask = "111";         # for both mydatafile1.dat and mydatafile2.dat

#my $visualization_mask = "11";

$clusterer->visualize_clusters($visualization_mask);

