use strict;
use warnings;

# applies a max threshold to a matrix. The max threshold is based on either
# the number of unique co-occurrences of a CUI, or the total number of 
# co-occurrences of a CUI. Any CUI that occurs more than the $maxThreshold
# number of times (or with $maxThreshold number of CUIs) is eliminated from
# the matrix. This is done by copying values from the $inputFile to the 
# $outputFile. $applyToUnique is used to toggle on or off unique number of
# CUIs threshold vs. total number of co-occurrences.

my $inputFile = '/home/henryst/lbdData/groupedData/reg/1975_1999_window8_noOrder';
my $outputFile = '/home/henryst/lbdData/groupedData/1975_1999_window8_noOrder_threshold5000u';
my $maxThreshold = 5000;
my $applyToUnique = 1;
my $countRef = &getStats($inputFile, $applyToUnique);
&applyMaxThreshold($inputFile, $outputFile, $maxThreshold, $countRef);


# gets co-occurrence stats, returns a hash of (unique) co-occurrence counts 
# for each CUI. (count is unique or not depending on $applyToUnique)
sub getStats {
    my $inputFile = shift;
    my $applyToUnique = shift;

    #open files
    open IN, $inputFile or die("ERROR: unable to open inputFile\n");   

    print "Getting Stats\n";
    #count stats for each line of the file
    my ($cui1, $cui2, $val);
    my %count = (); #a count of the number of (unique) co-occurrences
    while (my $line = <IN>) {
	#split the line
	($cui1, $cui2, $val) = split(/\t/,$line);

	if ($applyToUnique) {
	    #update the unique co-occurrence counts
	    $count{$cui1}++;
	}
	else {
	    #update the cooccurrence count
	    chomp $val; #I'm not sure if this is necassary...probably not
	    $count{$cui1}+=$val;
	}
	
	#NOTE: do not update counts for $2, because in the case where order 
	#does not matter, the matrix will have been pre-processed to ensure 
	#the second cui will appear first in the key. In the case where order 
	#does matter we just shouldnt be counting it anyway
    }
    close IN;

    return \%count;
}

#applies a maxThreshold, $countRef is the output of getStats
sub applyMaxThreshold {
    my $inputFile = shift;
    my $outputFile = shift;
    my $maxThreshold = shift;
    my $countRef = shift;

    #open the input and output
    open IN, $inputFile or die("ERROR: unable to open inputFile\n");
    open OUT, ">$outputFile" 
	or die ("ERROR: unable to open outputFile: $outputFile\n");

    print "ApplyingThreshold\n";
    #threshold each line of the file
    my ($cui1, $cui2, $val);
    while (my $line = <IN>) {
	#grab values 
	($cui1, $cui2, $val) = split(/\t/,$line);

	#skip if either $cui1 or $cui2 are greater than the threshold
	# the counts in %count have been set already according to 
	# whether $applyToUnique or not
	if (${$countRef}{$cui1} > $maxThreshold 
	    || ${$countRef}{$cui2} > $maxThreshold) {
	    next;
	}
	else {
	    print OUT $line;
	}

    }
    close IN;
    close OUT;

    print "Done!\n";
}

