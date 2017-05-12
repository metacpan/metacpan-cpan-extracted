#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';

use strict;
use Algorithm::KMeans;

# The Parameter File:

# How the synthetic data is generated for clustering is
# controlled entirely by the input_parameter_file keyword in
# the function call shown below.  The mean vector and
# covariance matrix entries in file must be according to the
# syntax shown in the example param.txt file.  It is best to
# edit this file as needed for the purpose of data
# generation.

#my $parameter_file = "param.txt";
#my $parameter_file = "param3.txt";
my $parameter_file = "param2.txt";
#my $out_datafile = "mydatafile2.dat";
my $out_datafile = "mydatafile3.dat";

Algorithm::KMeans->cluster_data_generator( 
                        input_parameter_file => $parameter_file,
                        output_datafile => $out_datafile,
                        number_data_points_per_cluster => 30 );

