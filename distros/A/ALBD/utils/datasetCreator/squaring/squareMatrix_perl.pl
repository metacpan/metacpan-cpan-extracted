#squares a matrix from file and writes the result to file
#use strict;
#use warnings;

#use Getopt::Long;

my $DEBUG = 0;
my $HELP = '';
my %options = ();

#GetOptions( 'debug'             => \$DEBUG, 
#            'help'              => \$HELP,
#            'inputFile=s'       => \$options{'inputFile'},
#	    'outputFile=s'      => \$options{'outputFile'},
#);
#TODO add stuff for help and debug

$options{'inputFile'} = shift;
$options{'outputFile'} = shift;

#input checking
(exists $options{'inputFile'}) or die ("inputFile must be specified\n");

#ensure the input file can be read
open IN, $options{'inputFile'} or 
    die ("unable to open input file: $options{inputFile}\n");
close IN;
(exists $options{'outputFile'}) or die ("outputFile must be specified\n");

#clear the output file and ensure it can be made
open OUT, '>'.$options{'outputFile'} or 
    die ("unable to open output file: $options{outputFile}\n");
close OUT;


#read in the matrix
my $matrixRef = fileToSparseMatrix($options{'inputFile'});

#loop over the rows of the B matrix
my %product = ();
my $count = 1;
my $total = scalar keys %{$matrixRef};
my $dumpThreshold = 20000; #dump to file every 20,000 keys
my $keyCount = 0;
foreach my $key0 (keys %{$matrixRef}) {  
    #loop over row
    foreach my $key1 (keys %{$matrixRef}) {	
	#loop over column
	foreach my $key2 (keys %{${$matrixRef}{$key1}}) {
	    #update values
	    if (exists ${${$matrixRef}{$key0}}{$key1}) {

		#update
		if (!exists ${$product{$key0}}{$key2}) {
		    ${$product{$key0}}{$key2} = 0;
		    $keyCount++;
		}
		${$product{$key0}}{$key2} += 
		    ${${$matrixRef}{$key0}}{$key1} * 
		    ${${$matrixRef}{$key1}}{$key2};
	
	    }
	}
	
	#output if needed
	if ($keyCount > $dumpThreshold) {
	    &outputMatrix(\%product, $options{'outputFile'});
	    $keyCount = 0;
	}

    }
    print STDERR "done with row: $count/$total\n";
    $count++;

    
}

#output any other elements in the matrix and finish
&outputMatrix(\%product, $options{'outputFile'});
print STDERR "DONE!\n";




#########################################################
# Helper Functions
#########################################################

sub outputMatrix {
    my $matrixRef = shift;
    my $outputFile = shift;

    #append to the output file
    print STDERR "outputFile = $outputFile\n";
    open OUT, '>>'.$outputFile or die ("ERROR: unable to open output file: $options{outputFile}\n");

    #ouput the matrix
    foreach my $key0 (keys %{$matrixRef}) {  
	foreach my $key1 (keys %{$product{$key0}}) {
	    print OUT "$key0\t$key1\t".${$product{$key0}}{$key1}."\n";
	}
    }
    
    #clear the matrix
    my %newHash = ();
    $matrixRef = \%newHash;

    close OUT;
}


sub fileToSparseMatrix {
    my $fileName = shift;

    open IN, $fileName or die ("unable to open file: $fileName\n");
    my %matrix = ();
    while (my $line = <IN>) {
	chomp $line;
	$line =~ /([^\t]+)\t([^\t]+)\t([\d]+)/;
	if (!exists $matrix{$1}) {
	    my %hash = ();
	    $matrix{$1} = \%hash;
	}
	$matrix{$1}{$2} = $3;
    }
    close IN;
    return \%matrix;
}
