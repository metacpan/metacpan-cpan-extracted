#!/usr/bin/perl -w

#  There should be no need to call this script ordinarily.

#  When the Algorithm::KMeans module creates new cluster files,
#  it automatically delete all previously created such files.
#  Such files are named ClusterX.dat for X starting with X = 0.
#  The files __temp_* are created by the visualization script.
#  However, when the program terminates properly, it should 
#  automatically delete those files.


unlink glob "cluster*.dat";

unlink glob "__temp_*";

