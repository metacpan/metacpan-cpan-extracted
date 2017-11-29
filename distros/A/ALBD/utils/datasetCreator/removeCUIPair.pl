# removes the cui pair from the dataset
# used to remove Somatomedic C and Arginine from the 1960-1989 datasets
use strict;
use warnings;

my $cuiA = 'C0021665'; #somatomedic c
my $cuiB = 'C0003765'; #arginine
my $matrixFileName = '/home/henryst/lbdData/groupedData/1960_1989_window8_ordered';
my $matrixOutFileName = $matrixFileName.'_removed';
&removeCuiPair($cuiA, $cuiB, $matrixFileName, $matrixOutFileName);

print STDERR "DONE\n";

###########################################
# remove the CUI pair from the dataset
sub removeCuiPair {
    my $cuiA = shift;
    my $cuiB = shift;
    my $matrixFileName = shift;
    my $matrixOutFileName = shift;
    print STDERR "removing $cuiA,$cuiB from $matrixFileName\n";
    
    #open the in and out files
    open IN, $matrixFileName 
	or die ("ERROR: cannot open matrix in file: $matrixFileName\n");
    open OUT, ">$matrixOutFileName" 
	or die ("ERROR: cannot open matrix out file: $matrixOutFileName\n");

    # read in each line of the matrix and copy to the new file
    # but omit any $cuiA,$cuiB or $cuiB,$cuiA lines
    while (my $line = <IN>) {
	if ($line =~ /$cuiA\t$cuiB/ || $line =~ /$cuiB\t$cuiA/) {
	    print "   removing $line";
	    next;
	}
	else {
	    print OUT $line;
	}
    }
}
