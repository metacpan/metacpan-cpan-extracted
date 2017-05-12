#!/usr/bin/perl -w

#  There should be no need to call this script ordinarily.

#  When the Algorithm::LinearManifoldDataClusterer module
#  creates new cluster files, it automatically deletes all
#  previously created such files.  Such files are named
#  ClusterX.dat for X starting with X = 0.  The files
#  __temp_* are created by the visualization script.  Those
#  files will also be deleted automatically if the program
#  terminates properly.

#  Should these files not be deleted automatically, you can
#  execute this script for cleaning up the directory.

unlink glob "cluster*.txt";

unlink glob "__temp_*";

unlink glob "clustering*at*iteration*.png";

unlink "initial_clusters.png";
unlink "final_clustering.png";
unlink glob "*produced_by_graph_partitioning.png";
