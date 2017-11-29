# A data statistics tool that gets a list of all cuis, and outputs their number
# of co-occurrences, and their number of unique co-occurrences to file

my $inputFile = '/home/henryst/lbdData/groupedData/reg/1975_1999_window8_noOrder';
my $outputFile = '/home/henryst/lbdData/groupedData/1975_1999_window8_noOrder_stats';

###################################
###################################

#open files
open IN, $inputFile or die("ERROR: unable to open inputFile\n");
open OUT, ">$outputFile" 
    or die ("ERROR: unable to open outputFile: $outputFile\n");


print "Reading File\n";
#count stats for each line of the file
my %ucoCount = (); #a count of the number of unique co-occurrences
my %coCount = (); #a count of the number of co-occurrences
my ($cui1, $cui2, $val);
while (my $line = <IN>) {
    #split the line
    ($cui1, $cui2, $val) = split(/\t/,$line);

    #update the cooccurrence count
    $coCount{$cui1}+=$val;
    
    #update the unique co-occurrence counts
    $ucoCount{$cui1}++;

    #NOTE: do not update counts for 2, because in the case where order 
    #does not matter, the matrix will have been pre-processed to ensure 
    #the second cui will appear first in the key. In the case where order 
    #does matter we just shouldnt be counting it anyway
}
close IN;

print "Outputting Results\n";
#output the co-occurrence counts, sorted by number of unique
# co-occurrences (descending)
foreach my $cui(sort {$ucoCount{$b}<=>$ucoCount{$a}} keys %ucoCount) {
    #coCount and ucoCount will have the same keys (see above loop)
    print OUT "$cui\t$coCount{$cui}\t$ucoCount{$cui}\n";
}
close OUT;

print "Done!\n";
