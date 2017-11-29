#checks that two sparse matrices are equal
use strict;
use warnings;

use Getopt::Long;
use LiteratureBasedDiscovery::Discovery;

my $DEBUG = 0;
my $HELP = '';
my %options = ();

GetOptions( 'debug'             => \$DEBUG, 
            'help'              => \$HELP,
            'inputFileA=s'       => \$options{'inputFileA'},
	    'inputFileB=s'      => \$options{'inputFileB'},
);
#TODO add stuff for help and debug

#input checking
(exists $options{'inputFileA'}) or die ("inputFileA must be specified\n");
open IN, $options{'inputFileA'} or 
    die ("unable to open input file: $options{inputFileA}\n");
close IN;
(exists $options{'inputFileB'}) or die ("inputFileB must be specified\n");
open IN, $options{'inputFileB'} or 
    die ("unable to open input file: $options{inputFileB}\n");
close IN;

#read in the matrices
my $matrixARef = Discovery::fileToSparseMatrix($options{'inputFileA'});
my $matrixBRef = Discovery::fileToSparseMatrix($options{'inputFileB'});

#check that matrix B has all the same elements as matrix A
my $equal = 1;
foreach my $key1 (keys %{$matrixARef}) {
    foreach my $key2 (keys %{${$matrixARef}{$key1}}) {

        #check that it exists in matrix B and that the value is the same
	if (exists ${${$matrixBRef}{$key1}}{$key2}) {
	    if (${${$matrixARef}{$key1}}{$key2} != ${${$matrixBRef}{$key1}}{$key2}) {
		$equal = 0;
		print "A\n";
		last;
	    }
	} else {
	    $equal = 0;
	    print "B\n";
	    last;
	}

	#remove from matrix B
	delete ${${$matrixBRef}{$key1}}{$key2};
    }
    if (!$equal) {
	last;
    }
}

#check the matrix B doesn't contain any elements that aren't in matrix A
if ($equal) {
    foreach my $key1 (keys %{$matrixBRef}) {	
	if (scalar keys %{${$matrixBRef}{$key1}} > 0) {
	    $equal = 0;
	    print "C\n";
	    last;
	}
    }
}

#print the reults
if ($equal) {
    print "Matrices are Equal\n";
} else {
    print "Matrices are NOT Equal\n";
}

print "DONE!\n";
