# determines the number of rows, columns, vocabulary size, and total number of 
# co-occurrences of a co-occurrence file, or set of co-occurrence files
use strict;
use warnings;

#perform meta-analysis on a single co-occurrence matrix
&metaAnalysis('/home/henryst/lbdData/groupedData/1960_1989_window8_noOrder');

#perform meta-analysis on a date range of co-occurrence matrices in a folder
# this expects a folder to contain a co-occurrence matrix for every year
# specified within the date range
my $dataFolder = '/home/henryst/lbdData/dataByYear/1960_1989';
my $startYear = '1809';
my $endYear = '2015';
my $windowSize = 1;
my $statsOutFileName = '/home/henryst/lbdData/stats_window1';
&folderMetaAnalysis($startYear, $endYear, $windowSize, $statsOutFileName, $dataFolder);


#####################
# runs meta analysis on a set of files
sub folderMetaAnalysis {
    my $startYear = shift;
    my $endYear = shift;
    my $windowSize = shift;
    my $statsOutFileName= shift;
    my $dataFolder = shift;

    #Check on I/O
    open OUT, ">$statsOutFileName" 
	or die ("ERROR: unable to open stats out file: $statsOutFileName\n");

    #print header row
    print OUT "year\tnumRows\tnumCols\tvocabularySize\tnumCooccurrences\n";

    #get stats for each file and output to file
    for(my $year = $startYear; $year <= $endYear; $year++) {
	print "reading $year\n";
	my $inFile = $dataFolder.$year.'_window'.$windowSize;
	if (open IN, $inFile) {
	    (my $numRows, my $numCols, my $vocabularySize, my $numCooccurrences)
		= &metaAnalysis($inFile);
	    print OUT "$year\t$numRows\t$numCols\t$vocabularySize\t$numCooccurrences\n"	
	}
	else {
	    #just skip the file
	    print "   ERROR: unable to open $inFile\n";
	}
    }
    close OUT;
    print "Done getting stats\n";
}


##############################
# runs meta analysis on a single file
sub metaAnalysis {
    my $fileName = shift;
    
    open IN, $fileName or die ("unable to open file: $fileName\n");
    
    my $numCooccurrences = 0; 
    my %rowKeys = ();  #number of rows
    my %colKeys = ();  #number of columns
    my %uniqueKeys = (); #vocabulary size
    while (my $line = <IN>) {
	$line =~ /([^\t]+)\t([^\t]+)\t([\d]+)/;
	#row = $1, col = $2, val = $3;
	$rowKeys{$1} = 1;
	$colKeys{$2} = 1;
	$uniqueKeys{$1} = 1;
	$uniqueKeys{$2} = 1;
	$numCooccurrences++;
    }
    close IN;

    my $numRows = scalar keys %rowKeys;
    my $numCols = scalar keys %colKeys;
    my $vocabularySize = scalar keys %uniqueKeys;
    
    print "$fileName: $numRows, $numCols, $vocabularySize, $numCooccurrences\n";

    return $numRows, $numCols, $vocabularySize, $numCooccurrences;
}
