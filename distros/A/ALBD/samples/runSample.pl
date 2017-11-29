#Demo file, showing how to run open discovery using the sample data, and how 
# to perform time slicing evaluation using the sample data

# run a sample lbd using the parameters in the lbd configuration file
print "\n           OPEN DISCOVERY          \n";
`perl ../utils/runDiscovery.pl lbdConfig`;
print "LBD Open discovery results output to sampleOutput\n\n";

# run a sample time slicing
# first remove the co-occurrences of the precutoff matrix (in this case it is 
# the sampleExplicitMatrix from the post cutoff matrix. This generates a gold 
# standard discovery matrix from which time slicing may be performed
# This requires modifying the removeExplicit.pl, which we have done for you. 
# The variables for this example in removeExplicit.pl are:
#  my $matrixFileName = 'sampleExplicitMatrix';
#  my $squaredMatrixFileName = postCutoffMatrix;
#  my $outputFileName = 'sampleGoldMatrix';
#`perl ../utils/datasetCreator/removeExplicit.pl`;

# next, run time slicing 
print "          TIME SLICING          \n";
`perl ../utils/runDiscovery.pl timeSlicingConfig > sampleTimeSliceOutput`;
print "LBD Time Slicing results output to sampleTimeSliceOutput\n";
