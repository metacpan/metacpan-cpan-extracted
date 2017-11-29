#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

use strict;
use warnings;
use Test::Simple tests => 10;

#error tolerance for exact numerical matches due to precision issues 
# and sort issues (again due to precision) there may be small
# differences between runs. The precision at K difference is 
# larger due to small differences in ranking making big differences
# in scores when the K < 10. See Rank::rankDescending for more
# details as to why the ranking imprecision occurrs
my $precRecallErrorTol = 0.0001;
my $atKErrorTol = 1.0;

#######################################################
# test script to run the sample code and compare its 
# output to the expected output. This tests both the 
# open and closed discovery code portions
#########################################################


#Test that the demo file can run correctly
`(cd ./samples/; perl runSample.pl) &`;

#######################################################
#test that the demo output matches the expected demo output
#########################################################
print "Performing Open Discovery Tests:\n";

#read in the gold scores from the open discovery gold
my %goldScores = ();
open IN, './t/goldSampleOutput' 
    or die ("Error: Cannot open gold sample output\n");
while (my $line = <IN>) {
    if ($line =~ /\d+\t(\d+\.\d+)\t(C\d+)/) {
	$goldScores{$2} = $1;
    }
}
close IN;

#read in the scores that were just generated
my %newScores = ();
open IN, './samples/sampleOutput' 
    or die ("Error: Cannot open sample output\n");
while (my $line = <IN>) {
    if ($line =~ /\d+\t(\d+\.\d+)\t(C\d+)/) {
	$newScores{$2} = $1;
    }
}
close IN;

#check that the number of keys in the input and output files are the same
ok(scalar keys %goldScores == scalar keys %newScores, "Number of Output CUIs match");

#check that the gold and sample scores match
my $allMatch = 1;
my $allExist = 1;
foreach my $key(keys %goldScores) {
    if (exists $newScores{$key}) {
	if ($newScores{$key} != $goldScores{$key}) {
	    $allMatch = 0;
	    last;
	}
    }
    else {
	$allExist = 0;
	$allMatch = 0;
	last;
    }
}
ok ($allExist == 1, "All CUIs exist in the output");  #all cuis exist in the new output file
ok ($allMatch == 1, "All Scores are the same in the output");  #all scores are the same in the new output file

print "Done with Open Discovery Tests\n\n";



#######################################################
#test that time slicing is computed correctly
#########################################################
print "Performing Time Slicing Tests\n";

#read in gold time slicing output
(my $goldAPScoresRef, my $goldMAP, my $goldPAtKScoresRef, my $goldFAtKScoresRef)
    = &readTimeSlicingData('./t/goldSampleTimeSliceOutput');

#read in new time slicing output
(my $newAPScoresRef, my $newMAP, my $newPAtKScoresRef, my $newFAtKScoresRef)
    = &readTimeSlicingData('./samples/sampleTimeSliceOutput');

#check that the correct number of values are read for all the 
# time slicing metrics
ok (scalar @{$newAPScoresRef} == 11, "Correct Count of Average Precisions");
ok (scalar @{$newPAtKScoresRef} == 19, "Correct Count of Precision at K's");
ok (scalar @{$newFAtKScoresRef} == 19, "Correct Count of Freq at K's");

#check that each of the AP scores match the gold (within error tolerance)
my $apSame = 1;
for (my $i = 0; $i < scalar @{$goldAPScoresRef}; $i++) {
    
    #check both comma seperated values (precision and recall)
    my @goldScores = split(',',${$goldAPScoresRef}[$i]);
    my @newScores = split(',',${$newAPScoresRef}[$i]);

    if ((abs($goldScores[0]-$newScores[0]) > $precRecallErrorTol)
	&& (abs($goldScores[1]-$newScores[1]) > $precRecallErrorTol)) {
	$apSame = 0;
	last;
    }
}
ok($apSame == 1, "Average Precisions Match");

#check MAP is the same (within error tolerance)
ok (abs($goldMAP - $newMAP) > $precRecallErrorTol, "Mean Average Precision Matches");

#check that each of Precision at K scores match the gold
# (within error tolerance)
my $pAtKSame = 1;
for (my $i = 0; $i < scalar @{$goldPAtKScoresRef}; $i++) {
    if (abs(${$goldPAtKScoresRef}[$i] - ${$newPAtKScoresRef}[$i]) > $atKErrorTol) {
	$pAtKSame = 0;
	last;
    }
}
ok($pAtKSame == 1, "Precision at K Matches");

#check that each of the Freq at K scores match the gold 
# (within error tolerance)
my $fAtKSame = 1;
for (my $i = 0; $i < scalar @{$goldFAtKScoresRef}; $i++) {
    if (abs(${$goldFAtKScoresRef}[$i] - ${$newFAtKScoresRef}[$i]) > $atKErrorTol) {
	$fAtKSame = 0;
	last;
    }
}
ok($fAtKSame == 1, "Frequency at K Matches");

print "Done with Time Slicing Tests\n";



############################################################
#function to read in time slicing data values
sub readTimeSlicingData {
    my $fileName = shift;

    #read in the gold time slicing values
    my @APScores = ();
    my $MAP;
    my @PAtKScores = ();
    my @FAtKScores = ();
    open IN, "$fileName" 
    #open IN, './t/goldSampleTimeSliceOutput'
	or die ("Error: Cannot open timeSliceOutput: $fileName\n");
    while (my $line = <IN>) {
	#read in the 11 values of average precision
	if ($line =~ /average precision at 10% recall intervals/ ) {
	    while (my $line2 = <IN>) {
		if ($line2 =~ /\d\s(\d\.?\d*)\s(\d\.\d*)/) {
		    push @APScores, "$1,$2";
		}
		else {
		    last;
		}
	    }
	}

	#read in the MAP value
	if ($line =~ /MAP = (\d+\.\d+)/ ) {
	    $MAP = $1;
	}

	#read in the 19 values of precision at k
	if ($line =~ /mean precision at k interval/ ) {
	    while (my $line2 = <IN>) {
		if ($line2 =~ /\d\s(\d\.\d*)/) {
		    push @PAtKScores, "$1";
		}
		else {
		    last;
		}
	    }
	}

	#read in the 19 values of frequency at k
	if ($line =~ /mean cooccurrences at k intervals/ ) {
	    while (my $line2 = <IN>) {
		if ($line2 =~ /\d+\s(\d\.?\d*)/) {
		    push @FAtKScores, "$1";
		}
		else {
		    last;
		}
	    }
	}
    }
    close IN;

    return (\@APScores, $MAP, \@PAtKScores, \@FAtKScores)
}
