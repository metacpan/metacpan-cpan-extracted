#makes the order of a CUIs not matter in a co-occurrence matrix and writes 
# the result to file
use strict;
use warnings;

use Getopt::Long;

my $DEBUG = 0;
my $HELP = '';
my %options = ();

GetOptions( 'debug'             => \$DEBUG, 
            'help'              => \$HELP,
            'inputFile=s'       => \$options{'inputFile'},
	    'outputFile=s'      => \$options{'outputFile'},
);
#TODO add stuff for help and debug

#input checking
(exists $options{'inputFile'}) or die ("inputFile must be specified\n");
open IN, $options{'inputFile'} or 
    die ("unable to open input file: $options{inputFile}\n");

(exists $options{'outputFile'}) or die ("outputFile must be specified\n");
open OUT, '>'.$options{'outputFile'} or 
    die ("unable to open output file: $options{outputFile}\n");

#make order not matter
#...output every $outputLimit iterations to avoid too much IO
my %matrix = ();
while (my $line = <IN>) {
    #TODO use split instead of regex match
    $line =~ /([^\s]+)\t([^\s]+)\t([^\s]+)/;
    #$1 = row, $2 = col, $3 = val

    if (!(defined $1) || !(defined $2) || !(defined $3)) {
	print "Not all defined: $line";
    }

    #initialize rows if needed
    if (!(exists $matrix{$1})) {
	my %newHash = ();
	$matrix{$1} = \%newHash;
    }
    if (!(exists $matrix{$2})) {
	my %newHash = ();
	$matrix{$2} = \%newHash;
    }

    #initialize cols if needed
    if (!(exists ${$matrix{$1}}{$2})) {
	${$matrix{$1}}{$2} = 0;
    }
    if (!(exists ${$matrix{$2}}{$1})) {
	${$matrix{$2}}{$1} = 0;
    }

    #add the value
    ${$matrix{$1}}{$2} += $3;
    #${$matrix{$2}}{$1} += $3;
}
close IN;

#output the matrix
foreach my $key1 (keys %matrix) {
    foreach my $key2 (keys %{$matrix{$key1}}) {
	print OUT "$key1\t$key2\t${$matrix{$key1}}{$key2}\n";
    }
}
foreach my $key1 (keys %matrix) {
    foreach my $key2 (keys %{$matrix{$key1}}) {
	print OUT "$key2\t$key1\t${$matrix{$key1}}{$key2}\n";
    }
}
close OUT;

print "DONE!\n";
