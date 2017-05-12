#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';


##  cluster_and_visualize_with_data_visualization.pl



##  IMPORTANT:  Read the 6 point customization of a script like this in the
##              file
##                       cluster_and_visualize.pl



##  The focus of this script is on the visualization steps after the data has been
##  clustered.  This script makes calls for the visualization of the data that was
##  used for clustering --- both the original data and the data after it is normed
##  for variance normalization (assuming you choose the variance normalization step,
##  which is not always a good thing).



use strict;
use Algorithm::KMeans;

#my $datafile = "mydatafile1.dat";
my $datafile = "sphericaldata.csv";

my $mask = "N111";

my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                        mask     => "N111",
                                        cluster_seeding => 'random',    # try 'smart' also
                                        K        => 3,
                                        terminal_output => 1,
                                        do_variance_normalization => 1,
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

# Read the comment block in cluster_and_visualize() that is associated with the
# setting up of the visualization mask.
my $visualization_mask = "111";

# In order to see the effects of variance normalization of the data (each data
# coordinate is normalized by the standard-deviation along that coordinate axis), it
# is sometimes useful to see both the raw data and its normalized form.  The
# following two calls accomplish that:
$clusterer->visualize_data($visualization_mask, 'original');
$clusterer->visualize_data($visualization_mask, 'normed');


# Finally, you can visualize the clusters.  BUT NOTE THAT THE VISUALIZATION MASK FOR
# CLUSTER VISUALIZATION WILL, IN GENERAL, BE INDEPENDENT OF THE VISUALIZATION MASK
# FOR VIEWING THE DATA:
$clusterer->visualize_clusters($visualization_mask);

