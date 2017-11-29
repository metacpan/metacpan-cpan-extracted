# combines the co-occurrences counts for the year range specified (inclusive 
# e.g. 1983-1985 will combine counts from files of 1983, 1984, and 1985 
# co-occurrences). This file is intended to run on co-occurrence matrices 
# created seperately for each year, and stored in a single folder. Creating
# co-occurrence matrices in this manner is useful because it makes running
# the CUICollector faster, and because files can be easily combined for
# different time slicing or discovery replication results. We ran CUI Collector
# seperately for each year of the MetaMapped MEDLINES baseline and stored each
# co-occurrence matrix in a single folder "hadoopByYear/output/". That folder 
# contained file named the year and window size used (e.g. 1975_window8).
# The code may need to be modified slightly for other purposes.
use strict;
use warnings;
my $startYear;
my $endYear;
my $windowSize;
my $dataFolder;

#user input
$dataFolder = '/home/henryst/hadoopByYear/output/';
$startYear = '1983';
$endYear = '1985';
$windowSize = 8;
&combineFiles($startYear,$endYear,$windowSize);


#####################################################
####### Program Start ########
sub combineFiles {
    my $startYear = shift;
    my $endYear = shift;
    my $windowSize = shift;

#Check on I/O
    my $outFileName = "$startYear".'_'."$endYear".'_window'."$windowSize";
(!(-e $outFileName)) 
    or die ("ERROR: output file already exists: $outFileName\n");
open OUT, ">$outFileName" 
    or die ("ERROR: unable to open output file: $outFileName\n");

#combine the files
my %matrix = ();
for(my $year = $startYear; $year <= $endYear; $year++) {
    print "reading $year\n";
    my $inFile = $dataFolder.$year.'_window'.$windowSize;
    if (!(open IN, $inFile)) {
	print "   ERROR: unable to open $inFile\n";
	next;
    }

    #read each line of the file and add to the matrix
    while (my $line = <IN>) {
	#read values from the line
	$line =~ /([^\s]+)\t([^\s]+)\t([^\s]+)/;
	my $rowKey = $1;
	my $colKey = $2;
	my $val = $3;

	#add the values to the matrix
	if (!exists $matrix{$rowKey}) {
	    my %newHash = ();
	    $matrix{$rowKey} = \%newHash;
	}
	if (!exists ${$matrix{$rowKey}}{$colKey}) {
	    ${$matrix{$rowKey}}{$colKey} = 0;
	}
	${$matrix{$rowKey}}{$colKey}+=$val;
    }
    close IN;
}

#output the matrix
print "outputting the matrix\n";
foreach my $rowKey(keys %matrix) {
    foreach my $colKey(keys %{$matrix{$rowKey}}) {
	print OUT "$rowKey\t$colKey\t${$matrix{$rowKey}}{$colKey}\n";
    }
}
close OUT;
print "DONE!\n";
}





