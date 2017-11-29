#removes the explicit co-occurrence matrix from the squared explicit 
# co-occurrence matrix. This generates a gold standard true discovery file

my $matrixFileName = '../../samples/sampleExplicitMatrix';
my $squaredMatrixFileName = '../../samples/postCutoffMatrix';
my $outputFileName = '../../samples/sampleGoldMatrix';

&removeExplicit($matrixFileName, $squaredMatrixFileName, $outputFileName);

###############################
###############################

#removes explicit knowledge ($matrixFileName) from the implicit 
# knowledge ($squaredMatrixFileName)
sub removeExplicit {
    my $matrixFileName = shift;  #the explicit knowledge matrix (usually not filtered)
    my $squaredMatrixFileName = shift;  #the implicit with explicit knowledge matrix (filtered squared)
    my $outputFileName = shift; #the implicit knowledge matrix output file
    print STDERR "Removing Explicit from $matrixFileName\n";

    #read in the matrix
    open IN, $matrixFileName 
	or die("ERROR: unable to open matrix input file: $matrixFileName\n");
    my %matrix = ();
    my $numCooccurrences = 0;
    while (my $line = <IN>) {
	#$line =~ /([^\t]+)\t([^\t]+)\t([\d]+)/;
	$line =~ /([^\s]+)\s([^\s]+)\s([\d]+)/;
	if (!exists $matrix{$1}) {
	    my %hash = ();
	    $matrix{$1} = \%hash;
	}
	$matrix{$1}{$2} = $3;
    }
    close IN;

    #copy the implicit values of the squared matrix over to a new file 
    open IN, $squaredMatrixFileName 
	or die("ERROR: unable to open squared matrix input file: $squaredMatrixFileName\n");
    open OUT, ">$outputFileName"
	or die("ERROR: unable to open output file: $outputFileName\n");
    while (my $line = <IN>) {
	$line =~ /([^\s]+)\s([^\s]+)\s([\d]+)/;
	if (!exists ${$matrix{$1}}{$2}) {
	    print OUT $line;
	}
    }
    close IN;
    close OUT;

    print STDERR "DONE!\n";
}



