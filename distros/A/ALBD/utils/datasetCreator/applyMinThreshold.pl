#Applies a minimum number of co-occurrences threshold to a file by 
#copying the $inputFile to $outputFile, but ommitting lines that have less than
#$minThreshold number of co-occurrences

my $minThreshold = 5;
my $inputFile = '/home/henryst/1975_2015_window8_noOrder_preThresh';
my $outputFile = '/home/henryst/1975_2015_window8_noOrder_threshold'.$minThreshold;
&applyMinThreshold($minThreshold, $inputFile, $outputFile);


############

sub applyMinThreshold {
    #grab the input
    my $minThreshold = shift;
    my $inputFile = shift;
    my $outputFile = shift;

    #open files
    open IN, $inputFile or die("ERROR: unable to open inputFile\n");
    open OUT, ">$outputFile" 
	or die ("ERROR: unable to open outputFile: $outputFile\n");

    print "Reading File\n";
    #threshold each line of the file
    my ($key, $cui1, $cui2, $val);
    while (my $line = <IN>) {
	#grab values 
	($cui1, $cui2, $val) = split(/\t/,$line);

	#check minThreshold
	if ($val > $minThreshold) {
	    print OUT $line;
	}  
    }
    close IN;

    print "Done!\n";
}
