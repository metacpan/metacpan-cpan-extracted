# functions to convert to and from assocLBD and MATLAB sparse matrix formats
use strict;
use warnings;

#convert to MATLAB sparse format
my $fileName = "1975_1999_window8_noOrder_threshold5_filtered";
&convertTo("/home/henryst/lbdData/groupedData/$fileName", 
	   "/home/henryst/lbdData/groupedData/forSquaring/$fileName".'_converted', 
	   "/home/henryst/lbdData/groupedData/forSquaring/$fileName".'_keys');

#convert from MATLAB sparse format
$fileName = "1980_1984_window1_ordered_filtered";
&convertFrom("/home/henryst/lbdData/groupedData/squared/$fileName".'_squared', "/home/henryst/lbdData/groupedData/squared/$fileName".'_squared_convertedBack',"/home/henryst/lbdData/groupedData/forSquaring/".$fileName.'_keys');


########################################
########################################

#converts the matrix to format for squaring in MATLAB
sub convertTo {
    #grab input
    my $inFile = shift;
    my $matrixOutFile = shift;
    my $keyOutFile = shift;
    print STDERR "converting $inFile\n";
  
    #open all the files
    open IN, $inFile
	or die ("ERROR: unable to open inFile: $inFile\n");
    open MATRIX_OUT, ">$matrixOutFile" 
	or die ("ERROR: unable to open matrixOutFile: $matrixOutFile\n");
    open KEY_OUT, ">$keyOutFile"
	or die ("ERROR: unable to open keyOutFile: $keyOutFile\n");

    #convert the infile to the proper format
    print "   outputting matrix\n";
    open IN, $inFile or die ("ERROR unable to reopen inFile: $inFile\n");
    my %keyHash = ();
    my ($cui1,$cui2,$value);
    while (my $line = <IN>) {
	#$line =~ /([^\s]+)\t([^\s]+)\t([^\s]+)/;
	#my $cui1 = $1;
	#my $cui2 = $2;
	#my $value = $3;
	($cui1,$cui2,$value) = split(/\t/,$line);

	if (!exists $keyHash{$cui1}) {
	    $keyHash{$cui1} = (scalar keys %keyHash)+1;
	}
	if (!exists $keyHash{$cui2}) {
	    $keyHash{$cui2} = (scalar keys %keyHash)+1;
	}

	#NOTE: $value has a \n character
	print MATRIX_OUT "$keyHash{$cui1}\t$keyHash{$cui2}\t$value";
    }
    close IN;

    #output the keys file
    print "   Outputting keys\n";
    foreach my $key (sort keys %keyHash) {
	print KEY_OUT "$key\t$keyHash{$key}\n";
    }
    close KEY_OUT;
    print "   DONE!\n";
}

#converts the from format for squaring in MATLAB
sub convertFrom {
    #grab input
    my $matrixInFile = shift;
    my $matrixOutFile = shift;
    my $keyInFile = shift;
    print "converting $matrixInFile\n";
  
    #open all the files
    open IN, $matrixInFile
	or die ("ERROR: unable to open matrixInFile: $matrixInFile\n");
    open MATRIX_OUT, ">$matrixOutFile" 
	or die ("ERROR: unable to open matrixOutFile: $matrixOutFile\n");
    open KEY_IN, $keyInFile
	or die ("ERROR: unable to open keyOutFile: $keyInFile\n");

    #read in all the keys
    my %keyHash = ();
    while (my $line = <KEY_IN>) {
	 #line is CUI\tkey
	 $line =~ /([^\s]+)\t([^\s]+)/;
	 $keyHash{$2}=$1;
     }
    close KEY_IN;

    #read in the file and convert on output
    while (my $line = <IN>) {
	$line =~ /([^\s]+)\s([^\s]+)\s([^\s]+)/;
	my $key1 = $1;
	my $key2 = $2;
	my $value = $3;

	print MATRIX_OUT "$keyHash{$key1}\t$keyHash{$key2}\t$value\n";
    }
    close IN;
    close MATRIX_OUT;
    print "   DONE!\n";
}
