#!/usr/bin/perl -w

use lib '../blib/lib', '../blib/arch';

use strict;
use Algorithm::ExpectationMaximization;

# The Parameter File:

# How the synthetic data is generated for clustering is
# controlled entirely by the input_parameter_file keyword in
# the function call shown below.  The class prior
# probabilities, the mean vectors and covariance matrix
# entries in file must be according to the syntax shown in
# the example param.txt file.  It is best to edit that file
# as needed for the purpose of data generation.

#my $parameter_file = "param1.txt";             #2D
#my $parameter_file = "param2.txt";             #2D     
#my $parameter_file = "param3.txt";             #2D
#my $parameter_file = "param4.txt";             #3D    
#my $parameter_file = "param5.txt";             #3D    
#my $parameter_file = "param6.txt";             #3D    
my $parameter_file = "param7.txt";             #1D    

#my $out_datafile = "mydatafile1.dat";
#my $out_datafile = "mydatafile2.dat";
#my $out_datafile = "mydatafile3.dat";
#my $out_datafile = "mydatafile4.dat";
#my $out_datafile = "mydatafile5.dat";
#my $out_datafile = "mydatafile6.dat";
my $out_datafile = "mydatafile7.dat";

Algorithm::ExpectationMaximization->cluster_data_generator( 
                        input_parameter_file => $parameter_file,
                        output_datafile => $out_datafile,
                        total_number_of_data_points => 200 );

