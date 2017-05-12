#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';


##  cluster_and_visualize.pl

##  This is the most basic script in the `examples' directory of the Algorithm::KMeans
##  module.  This script shows how the module is supposed to be called for clustering 
##  your data file.  You must experiment with all of the different options at the
##  six locations mentioned below in order to become more familiar with the capabilities
##  of the module.

##  Needs customization at SIX locations:
##
##      1) First choose which data file you want to use for clustering
##
##
##      2) Next, choose the data mask to apply to the columns of the data file.  The
##           position of the letter `N' in the mast indicates the column that
##           contains a symbolic name for each data record.  If the symbolic name for
##           each data record is in the first column and you want to cluster 3D data
##           that is in the next three columns, your data mask will be N111.  On the
##           other hand, if for the same data file, you want to carry out 2D
##           clustering on the last two columns, your data mask will be N011.
##
##      3) Next, you need to decide how many clusters you want the program to return.
##           If you want the program to figure out on its own how many clusters to 
##           partition the data into, see the script find_best_K_and_cluster.pl in this
##           directory.
##
##      4) Next you need to decide whether you want to `random' seeding or `smart'
##           seeding.  Bear in mind that `smart' seeding may produce worse results
##           than `random' seeding, depending on how the data clusters are actually
##           distributed.  
##
##      5) Next you need to decide whether or not you want to use the Mahalanobis
##           distance metric for clustering.  The default is the Euclidean metric.
##
##      6) Finally, you need to choose a mask for visualization.  Here is a reason
##           for why the visualization mask is set independently of the data mask
##           that was specified in Step 2: Let's say your datafile has 8 columns and
##           you are choosing to cluster the data records using 4 of those.
##           Subsequently, you may want to visually examine the quality of clustering
##           by examining some or 2D or 3D subspace of of the 4-dimensional space
##           used for clustering


use strict;
use Algorithm::KMeans;


my $datafile = "mydatafile2.dat";           #  use:  K = 2,  mask = "N111",  vmask = "N111"
#my $datafile = "sphericaldata.csv";        #  use:  K = 3,  mask = "N111",  vmask = "N111"
#my $datafile = "mydatafile1.dat";          #  use:  K = 3,  mask = "N111",  vmask = "N111"
#my $datafile = "mydatafile3.dat";          #  use:  K = 2,  mask = "N11" ,  vmask = "N11"


# Mask: (For emphasis, this is a slightly more detailed repetition of the comment
# made above in Item 2)

# The mask tells the module which columns of the data file are are to be used for
# clustering, which columns are to be ignored, and which column contains a symbolic
# ID tag for a data point.  If the ID tag is in the first column and you are
# clustering 3D data in a file that has just four columns, the mask would be "N111".
# Note the first character in the mask in this case is `N' for "Name".  If, on the
# other hand, you wanted to ignore the first data coordinate (which is in the second
# column of the data file) for clustering, the mask would be "N011".  The symbolic ID
# can be in any column --- you just have to place the character `N' at the right
# place:


my $mask = "N111";         # for mydatafile1.dat, mydatafile2.dat, and sphericaldata.csv 
#my $mask = "N011";        # for mydatafile1.dat --- use all only last two cols
#my $mask = "N100";        # for mydatafile1.dat --- use only the first coordinate
#my $mask = "N11";         # for mydatafile3.dat


my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                        mask     => $mask,
                                        K        => 2,
                                        cluster_seeding => 'random',   # also try 'smart'
#                                        use_mahalanobis_metric => 1,   # also try '0'
                                        terminal_output => 1,
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


# VISUALIZATION:

# Visualization mask:

# In most cases, you would not change the value of the mask between clustering and
# visualization.  But, if you are clustering multi-dimensional data and you wish to
# visualize the projection of of the data on each plane separately, you can do so by
# changing the value of the visualization mask.  The number of on bits in the
# visualization must not exceed the number of on bits in the original data mask.

my $vmask = "111";                 # for mydatafile1.dat and mydatafile2.dat
#my $vmask = "11";                 # for mydatafile3.dat

$clusterer->visualize_clusters( $vmask );

