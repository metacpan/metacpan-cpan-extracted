#gets matrix stats for a matrix file 
# (number of rows, number of columns, number of keys)

&getStats('/home/henryst/lbdData/groupedData/1852_window1_squared_inParts');


#############################################
# gets the stats for the matrix
#############################################
sub getStats {
    my $fileName = shift;
    print STDERR "$fileName\n";

#read in the matrix
    open IN, $fileName or die ("unable to open file: $fileName\n");
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
	$numCooccurrences += $3;
    }
    close IN;

    print STDERR "   num rows in matrix = ".(scalar keys %matrix)."\n";

#count the number of columns and the number of keys
# this is done outside of the loop above because I also need to count the number of columns
    my $numKeys = 0;
    my %colKeys = ();
    foreach my $row (keys %matrix) {
	foreach my $colKey (keys %{$matrix{$row}}) {
	    $colKeys{$colKey} = 1;
	    $numKeys++;
	}
    }

    print STDERR "   num columns in matrix = ".(scalar keys %colKeys)."\n";
    print STDERR "   number of keys in the matrix = $numKeys\n";
    print STDERR "   number of cooccurrences in the matrix = $numCooccurrences\n";
}
