# ALBD::TimeSlicing
#
# Library module of time slicing methods for LBD
#
# Copyright (c) 2017
#
# Sam Henry
# henryst at vcu.edu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to
#
# The Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.

package TimeSlicing;
use strict;
use warnings;

use LiteratureBasedDiscovery::Discovery;


#
# Calculates and outputs to STDOUT Time Slicing evaluation stats of
# precision and recall at $numIntervals intervals, Mean Average Precision
# (MAP), precision at k, and frequency at k
# input:  $trueMatrixRef <- a ref to a hash of true discoveries
#         $rowRanksRef <- a ref to a hash of arrays of ranked predictions. 
#                         Each hash key is a cui,  each hash element is an 
#                         array of ranked predictions for that cui. The ranked 
#                         predictions are cuis are ordered in descending order 
#                         based on association. (from Rank::RankDescending)
#         $numIntervals <- the number of recall intervals to generate
sub outputTimeSlicingResults {
    #grab the input
    my $goldMatrixRef = shift;
    my $rowRanksRef = shift;
    my $numIntervals = shift;


#calculate and output stats
#------------------------------------------

 #calculate precision and recall
    print "calculating precision and recall\n";
    my ($precisionRef, $recallRef) = &calculatePrecisionAndRecall_implicit(
	 $goldMatrixRef, $rowRanksRef, $numIntervals);

    #output precision and recall
    print "----- average precision at 10% recall intervals (i recall precision) ----> \n";
    foreach my $i (sort {$a <=> $b} keys %{$precisionRef}) {
	print "      $i ${$recallRef}{$i} ${$precisionRef}{$i}\n";
    }
    print "\n";
    
#-------------------------------------------
    
    #calculate mean average precision
    my $map = &calculateMeanAveragePrecision(
	$goldMatrixRef, $rowRanksRef);
    #output mean average precision
    print "---------- mean average precision ---------------> \n";
    print "      MAP = $map\n";
    print "\n";

#-------------------------------------------
    
    #calculate precision at k
    print "calculating precision at k\n";
    my $precisionAtKRef = &calculatePrecisionAtK($goldMatrixRef, $rowRanksRef);
    #output precision at k
    print "---------- mean precision at k intervals ---------------> \n";
    foreach my $k (sort {$a <=> $b} keys %{$precisionAtKRef}) {
	print "      $k ${$precisionAtKRef}{$k}\n";
    }
    print "\n";

#-------------------------------------------
    
    #calculate cooccurrences at k
    print "calculating mean cooccurrences at k\n";
    my $cooccurrencesAtKRef = &calculateMeanCooccurrencesAtK($goldMatrixRef, $rowRanksRef);
    #output cooccurrences at k
    print "---------- mean cooccurrences at k intervals ---------------> \n";
    foreach my $k (sort {$a <=> $b} keys %{$cooccurrencesAtKRef}) {
	print "      $k ${$cooccurrencesAtKRef}{$k}\n";
    }
    print "\n";

}


# loads a list of cuis for use in time slicing from file
# the CUI file contains a line seperated list of CUIs
# input:  $cuiFileName <- a string specifying the file to load cuis from
# output: $\%cuis <- a ref to a hash of cuis, each key is a cui, values are 1
sub loadCUIs {
    my $cuiFileName = shift;
    
    #open the file
    open IN, $cuiFileName 
	or die("ERROR: cannot open CUI File: $cuiFileName\n");
    
    #read each line of the file
    my %cuis = ();
    while (my $line = <IN>) {
	chomp $line;
	
	#only add the line if it properly formatted
	if ($line =~ /C\d{7}/) {
	    $cuis{$line} = 1;
	}
    }
    close IN;

    return \%cuis;
}


# calculates average precision and recall of the generated implicit matrix 
# compared to the post cutoff matrix
# input:  $predictionsMatrixRef <- a ref to a sparse matrix of predicted 
#                                  discoveries
#         $trueMatrixRef <- a ref to a sparse matrix of true discoveries
# output: ($precision, $recall) <- two scalar values specifying the precision 
#                                  and recall
sub calculatePrecisionRecall {
    my $predictionsMatrixRef = shift; #a matrix of predicted discoveries
    my $trueMatrixRef = shift; #a matrix of true discoveries
    print "calculating precision and recall\n";

    #bounds check, the predictions matrix must contain keys
    if ((scalar keys %{$predictionsMatrixRef}) < 1) {
	return (0,0); #precision and recall are both zero
    }

    #calculate precision and recall averaged over each cui
    my $precision = 0;
    my $recall = 0;
    #each row key corresponds to a term for which we calculate
    # precision and recall. From each term's precision and recall
    # we calculate an average over all terms
    foreach my $rowKey (keys %{$trueMatrixRef}) {

	#calculate precision for this term
	my $truePositive = 0;
	my $falsePositive = 0;
	foreach my $colKey (keys %{${$predictionsMatrixRef}{$rowKey}}) {
	    if (exists ${${$trueMatrixRef}{$rowKey}}{$colKey}) {
		$truePositive++;
	    } else {
		$falsePositive++;
	    }
	}

	#calculate precision and recall for this term
	# and add it to the sum of precision and recall
	# over all terms
	if ($truePositive+$falsePositive > 0) {
	    $precision += 
		($truePositive/($truePositive+$falsePositive)); 
	} #else precision += 0 ... nothing needs to be done
	if ((scalar keys %{${$trueMatrixRef}{$rowKey}}) > 0) {
	    $recall += 
		($truePositive/
		 (scalar keys %{${$trueMatrixRef}{$rowKey}}));
	} #else recall += 0
    }

    #calculate the averages (divide by the number of rows 
    #    = the number of terms in the post cutoff matrix)
    $precision /= scalar keys %{$trueMatrixRef};
    $recall /= scalar keys %{$trueMatrixRef};

    #return the average precision and recall
    return ($precision, $recall);
}


# loads the post cutoff matrix from file. Only loads rows corresponding
# to rows in the starting matrix ref to save memory, and because those are 
# the only rows that are needed.
# input:  $startingMatrixRef <- a ref to the starting sparse matrix
#         $explicitMatrix Ref <- a ref to the explicit sparse matrix
#         $postCutoffFileName <- the filename to the postCutoffMatrix
# output: \%postCutoffMatrix <- a ref to the postCutoff sparse matrix
sub loadPostCutOffMatrix {
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $postCutoffFileName = shift;
    print "loading postCutoff Matrix\n";
    
    #open the post cutoff file
    open IN, $postCutoffFileName 
	or die ("ERROR: cannot open post cutoff file: $postCutoffFileName");

    #create hash of cuis to grab
    my %cuisToGrab = ();
    foreach my $rowKey (keys %{$startingMatrixRef}) {
	$cuisToGrab{$rowKey} = 1;
    }

    #read in values of the post cutoff matrix for the start terms
    my %postCutoffMatrix = ();
    my ($cui1, $cui2, $val);
    while (my $line = <IN>) {
	#grab values from the line
	chomp $line;
	($cui1, $cui2, $val) = split(/\t/,$line);

	#see if this line contains a key that should be read in 
	if (exists $cuisToGrab{$cui1}) {

	    #add the value
	    if (!(defined $postCutoffMatrix{$cui1})) {
		my %newHash = ();
		$postCutoffMatrix{$cui1} = \%newHash;
	    }

	    #check to ensure that the column cui is in the 
	    #  vocabulary of the pre-cutoff dataset.
	    #  it is impossible to make predictions of words that
	    #  don't already exist
	    #NOTE: this assumes $explicitMatrixRef is a square 
	    #   matrix (so unordered)
	    if (exists ${$explicitMatrixRef}{$cui2}) {
		${$postCutoffMatrix{$cui1}}{$cui2} = $val;
	    }
	}
    }
    close IN;

    #return the post cutoff matrix
    return \%postCutoffMatrix;
}

#TODO numRows should be read from file and sent with the lbdOptionsRef
# generates a starting matrix of numRows randomly selected terms
# input:  $explicitMatrixRef <- a ref to the explicit sparse matrix
#         $lbdOptionsRef <- the LBD options
#         $startTermAcceptTypesRef <- a reference to an hash of accept 
#                                     types for start terms (TUIs)
#         $numRows <- the number of random rows to load (if random)
#         $umls_interface <- an instance of the UMLS::Interface
# output: \%startingMatrix <- a ref to the starting sparse matrix
sub generateStartingMatrix {
    my $explicitMatrixRef = shift;
    my $lbdOptionsRef = shift;
    my $startTermAcceptTypesRef = shift;
    my $numRows = shift;
    my $umls_interface = shift;

    #generate the starting matrix randomly or from a file
    my %startingMatrix = ();

    #check if a file is defined
    if (exists ${$lbdOptionsRef}{'cuiListFileName'}) {
	#grab the rows defined by the cuiListFile
	my $cuisRef = &loadCUIs(${$lbdOptionsRef}{'cuiListFileName'});
	foreach my $cui (keys %{$cuisRef}) {
	    if(exists ${$explicitMatrixRef}{$cui}) {
		$startingMatrix{$cui} = ${$explicitMatrixRef}{$cui};	
	    }
	    else {
		print STDERR "WARNING: CUI from cuiListFileName is not in explicitMatrix: $cui\n";
	    }
	}
    }
    else {
	#randomly grab rows
	#apply semantic filter to the rows (just retreive appropriate rows)
	my $rowsToKeepRef = getRowsOfSemanticTypes(
	    $explicitMatrixRef, $startTermAcceptTypesRef, $umls_interface);
	((scalar keys %{$rowsToKeepRef}) >= $numRows) or die("ERROR: number of acceptable rows starting terms is less than $numRows\n");

	#randomly select 100 rows (to generate the 'starting matrix')
	#generate random numbers from 0 to number of rows in the explicit matrix
	my %rowNumbers = ();
	while ((scalar keys %rowNumbers) < $numRows) {
	    $rowNumbers{int(rand(scalar keys %{$rowsToKeepRef}))} = 1;
	}

	#fill starting matrix with keys corresponding to the random numbers 
	my $i = 0;
	foreach my $key (keys %{$rowsToKeepRef}) {
	    if (exists $rowNumbers{$i}) {
		$startingMatrix{$key} = ${$explicitMatrixRef}{$key}
	    }
	    $i++;
	}

	#output the cui list if needed
	if (exists ${$lbdOptionsRef}{'cuiListOutputFile'}) {
	    open OUT, ">".${$lbdOptionsRef}{'cuiListOutputFile'} or die ("ERROR: cannot open cuiListOutputFile:".${$lbdOptionsRef}{'cuiListOutputFile'}."\n");
	    foreach my $cui (keys %startingMatrix) {
		print OUT "$cui\n";
	    }
	    close OUT;
	}
    }

    #return the starting matrix
    return \%startingMatrix;
}


# gets and returns a hash of row keys of the specifies semantic types
# input:  $matrixRef <- a ref to a sparse matrix
#         $acceptTypesRef <- a ref to a hash of accept types (TUIs)
#         $umls <- an instance of UMLS::Interface
# output: \%rowsToKeep <- a ref to hash of rows to keep, each key is 
#                         a CUI, and values are 1. All CUIs specify rows
#                         of acceptable semantic types
sub getRowsOfSemanticTypes {
    my $matrixRef = shift;
    my $acceptTypesRef = shift;
    my $umls = shift;
    
    #loop through the matrix and keep the rows that are of the 
    # desired semantic types
    my %rowsToKeep = ();
    foreach my $cui1 (keys %{$matrixRef}) {
	my $typesRef = $umls->getSt($cui1);
	foreach my $type(@{$typesRef}) {
	    my $abr = $umls->getStAbr($type);

	    #check the cui for removal
	    if (exists ${$acceptTypesRef}{$type}) {
		$rowsToKeep{$cui1} = 1;
		last;
	    }
	}
    }

    #return the rowsToKeep
    return \%rowsToKeep
}

# generates a hash of all association scores from the matrix
# the hash keys are $rowKey,$colKey. Hash values are the association scores
# between the $rowKey and $colKey. All co-occurring cui pairs from the matrix
# are calculated
# input:  $matrixRef <- a reference to a sparse matrix
#         $rankingMeasue <- a string specifying the ranking measure to use
#         $umls_association <- an instance of UMLS::Association
# output: \%cuiPairs <- a ref to a hash of CUI pairs and their assocaition
#                       each key of the hash is a comma seperated string 
#                       containing cui1, and cui2 of the pair 
#                       (e.g. 'cui1,cui2'), and each value is their association
#                       score using the specified assocition measure
sub getAssociationScores {
    my $matrixRef = shift;
    my $rankingMeasure = shift;
    my $umls_association = shift;
    print "   getting Association Scores, rankingMeasure = $rankingMeasure\n";
    
    #generate a list of cui pairs in the matrix
    my %cuiPairs = ();
    print "   generating association scores:\n";
    foreach my $rowKey (keys %{$matrixRef}) {
	foreach my $colKey (keys %{${$matrixRef}{$rowKey}}) {
	    $cuiPairs{"$rowKey,$colKey"} = ${${$matrixRef}{$rowKey}}{$colKey};
	}
    }
    
    #get ranks for all the cui pairs in the matrix
    #return a hash of cui pairs and their frequency
    if ($rankingMeasure eq 'frequency') {
	return \%cuiPairs;
    } else {
	#updates values in cuiPairs hash with their association scores and returns
	Rank::getBatchAssociationScores(\%cuiPairs, $matrixRef, $rankingMeasure, $umls_association);
	return \%cuiPairs;
    }
}

# gets the min and max value of a hash
# returns a two element array, where the first value is the min, and
# the second values is the max
# input:  $hashref <- a reference to a hash with numbers as values
# output: ($min, $max) <- the minimum and maximum values in the hash
sub getMinMax {
    my $hashRef = shift;
    
    #loop through each key and record the min/max
    my $min = 999999;
    my $max = -999999;
    foreach my $key (keys %{$hashRef}) {
	my $val = ${$hashRef}{$key};
	if ($val < $min) {
	    $min = $val;
	}
	if ($val > $max) {
	    $max = $val;
	}
    }
    return ($min,$max);
}

# Applies a threshold to a matrix using a corresponding association scores
# hash. Any keys less than the threshold are not copied to the new matrix
# input:  $threshold <- a scalar threshold
#         $assocScoresRef <- a reference to a cui pair hash of association
#                            scores. Each key is a comma seperated cui pair
#                            (e.g. 'cui1,cui2'), values are their association
#                            scores.
#         $matrixRef <- a reference to a co-occurrence sparse matrix that 
#                       corresponds to the assocScoresRef
# output: \%thresholdedMatrix < a ref to a new matrix, built from the 
#         $matrixRef after applying the $threshold
sub applyThreshold {
    my $threshold = shift;
    my $assocScoresRef = shift;
    my $matrixRef = shift;

    #apply the threshold
    my $preKeyCount = scalar keys %{$assocScoresRef};
    my $postKeyCount = 0;
    my %thresholdedMatrix = ();
    my ($cui1, $cui2);
    foreach my $key (keys %{$assocScoresRef}) {

	#add key if val >= threshold
	if (${$assocScoresRef}{$key} >= $threshold) {
	    ($cui1,$cui2) = split(/,/, $key);

	    #create new hash at rowkey location
	    if (!(exists $thresholdedMatrix{$cui1})) {
		my %newHash = ();
		$thresholdedMatrix{$cui1} = \%newHash;
	    }
	    #set key value
	    ${$thresholdedMatrix{$cui1}}{$cui2} = ${${$matrixRef}{$cui1}}{$cui2};
	    $postKeyCount++;
	}
    }

    #return the thresholded matrix
    return \%thresholdedMatrix;
}

# Grabs the K highest ranked samples. This is for thresholding based the number 
# of samples. Used in explicit timeslicing
# input:  $k <- the number of samples to get
#         $assocScoresRef <- a reference to a cui pair hash of association
#                            scores. Each key is a comma seperated cui pair
#                            (e.g. 'cui1,cui2'), values are their association
#                            scores.
#         $matrixRef <- a reference to a co-occurrence sparse matrix that 
#                       corresponds to the assocScoresRef
# output: \%thresholdedMatrix <- a ref to a sparse matrix containing only the 
#                                $k ranked samples (cui pairs)
sub grabKHighestRankedSamples {
    my $k = shift;
    my $assocScoresRef = shift;
    my $matrixRef = shift;
    print "getting $k highest ranked samples\n";

    #apply the threshold
    my $preKeyCount = scalar keys %{$assocScoresRef};
    my $postKeyCount = 0;
    my %thresholdedMatrix = ();

    #get the keys sorted by value in descending order
    my @sortedKeys = sort { $assocScoresRef->{$b} <=> $assocScoresRef->{$a} } keys(%$assocScoresRef);
    my $threshold =  ${$assocScoresRef}{$sortedKeys[$k-1]};
    print " threshold = $threshold\n";

    #add the first k keys to the thresholded matrix
    my ($cui1, $cui2);
    foreach my $key (@sortedKeys) {
	($cui1, $cui2) = split(/,/, $key);

	#create new hash at rowkey location (if needed)
	if (!(exists $thresholdedMatrix{$cui1})) {
	    my %newHash = ();
	    $thresholdedMatrix{$cui1} = \%newHash;
	}

	#set key value for the key pair
	${$thresholdedMatrix{$cui1}}{$cui2} = ${${$matrixRef}{$cui1}}{$cui2};
	$postKeyCount++;

	#stop adding keys when below the threshold
	if (${$assocScoresRef}{$key} < $threshold) {
	    last;
	}
    }
    #return the thresholded matrix
    return \%thresholdedMatrix;
}


# calculates precision and recall at $numIntervals (e.g. 10 for 10%) recall 
# intervals using an implicit ranking threshold
# input:  $trueMatrixRef <- a ref to a hash of true discoveries
#         $rowRanksRef <- a ref to a hash of arrays of ranked predictions. 
#                         Each hash key is a cui,  each hash element is an 
#                         array of ranked predictions for that cui. The ranked 
#                         predictions are cuis are ordered in descending order 
#                         based on association. (from Rank::RankDescending)
#         $numIntervals <- the number of recall intervals to generate
# output: (\%precision, \%recall) <- refs to hashes of precision and recall. 
#                                    Each hash key is the interval number, and 
#                                    the value is the precision and recall 
#                                    respectively
sub calculatePrecisionAndRecall_implicit {
    my $trueMatrixRef = shift; #a ref to the true matrix
    my $rowRanksRef = shift; #a ref to ranked predictions, each hash element are the predictions for a single cui, at each element is an array of cuis ordered by their rank
    my $numIntervals = shift; #the recall intervals to test at

    #find precision and recall curves for each cui that is being predicted
    #  take the sum of precisions, then average after the loop
    my %precision = ();
    my %recall = ();
    foreach my $rowKey (keys %{$trueMatrixRef}) {
	my $trueRef = ${$trueMatrixRef}{$rowKey}; #a list of true discoveries
	my $rankedPredictionsRef = ${$rowRanksRef}{$rowKey}; #an array ref of ranked predictions
	
	#get the number of predicted discoveries and true discoveries
	my $numPredictions = scalar @{$rankedPredictionsRef};
	my $numTrue = scalar keys %{$trueRef};

	#skip if there are NO new discoveries for this start term
	if ($numTrue == 0) {
	    next;
	}
	#skip if there are NO predictions for this start term
	if ($numPredictions == 0) {
	    next;
	}

	#determine precision and recall at 10% intervals of the number of 
	#predicted true vaules. This is done by simulating a threshold being
	#applied, so the top $numToTest ranked terms are tested at 10% intervals
	my $interval = $numPredictions/$numIntervals;
	for (my $i = 0; $i <= 1; $i+=(1/$numIntervals)) {
	    
	    #determine the number true to grab
	    my $numTrueForInterval = 1; #at $i = 0, grab just the first term that is true
	    if ($i > 0) {
		$numTrueForInterval = $numTrue*$i;
	    }

	    #grab true discoveries until the recall rate is exceeded
	    my $truePositive = 0;
	    my $numChecked = 0;
	    for (my $j = 0; $j < $numPredictions; $j++) {

		#get the jth ranked cui and check if it is a true discovery
		my $cui = ${$rankedPredictionsRef}[$j];
		if (exists ${$trueRef}{$cui}) {
		    $truePositive++;
		}
		$numChecked++;

		#check if the recall rate has been reached
		if ($truePositive > $numTrueForInterval) {
		    last;
		}
	    }
	    #sum precision at this interval, average over number of rows is 
	    # taken outside of the loop
	    $precision{$i} += ($truePositive / $numChecked); #number that are selected that are true
	    $recall{$i} += ($truePositive / $numTrue); #number of true that are selected	
	}
    }

    #calculate the average precision at each interval
    foreach my $i (keys %precision) {
	#divide by the number of rows in the true matrix ref
	# because those are the number of cuis we are testing
	# it is possible that the predictions has rows that are 
	# not in the true, and those should be ignored.
	$precision{$i} /= (scalar keys %{$trueMatrixRef});
	$recall{$i} /= (scalar keys %{$trueMatrixRef});
    }

    #return the precision and recall at 10% intervals
    return (\%precision, \%recall);
}



# calculates the mean average precision (MAP)
# input:  $trueMatrixRef <- a ref to a hash of true discoveries
#         $rowRanksRef <- a ref to a hash of arrays of ranked predictions. 
#                         Each hash key is a cui,  each hash element is an 
#                         array of ranked predictions for that cui. The ranked 
#                         predictions are cuis are ordered in descending order 
#                         based on association. (from Rank::RankDescending)
# output: $map <- a scalar value of mean average precision (MAP)
sub calculateMeanAveragePrecision {
    #grab the input
    my $trueMatrixRef = shift; # a matrix of true discoveries
    my $rowRanksRef = shift; # a hash of ranked predicted discoveries
    print "calculating mean average precision\n";

    #calculate MAP for each true discovery being predicted
    my $map = 0;
    foreach my $rowKey (keys %{$trueMatrixRef}) {
	my $rankedPredictionsRef = ${$rowRanksRef}{$rowKey}; #an array ref of ranked predictions

	#skip for rows that have no predictions
	if (!defined $rankedPredictionsRef) {
	    next;
	} 
	my $trueRef = ${$trueMatrixRef}{$rowKey}; #a list of true discoveries
	my $numPredictions = scalar @{$rankedPredictionsRef};

	#calculate the average precision of this true cui, by comparing 
	# the predicted vs. true values ordered and weighted by their rank
	my $ap = 0; #average precision
	my $truePositiveCount = 0;
	#start at 1, since divide by rank...subtract one when indexing
	for (my $rank = 1; $rank <= $numPredictions; $rank++) {
	    my $cui = ${$rankedPredictionsRef}[$rank-1];
	    if (exists ${$trueRef}{$cui}) {
		$truePositiveCount++;
		$ap += ($truePositiveCount/($rank));
	    }
	}

	#calculate the average precision, and add to map
	if ($truePositiveCount > 0) {
	    $ap /= $truePositiveCount;
	} #else, $ap is already 0 so do nothing
	$map += $ap;
    }

    #take the mean of the average precisions
    # divide by the number of true discoveries that you summed over
    $map /= (scalar keys %{$trueMatrixRef});

    #return the mean average precision
    return $map;
}


# calculates the mean precision at k at intervals of 1, 
# from k = 1-10 and intervals of 10 for 10-100
# input:  $trueMatrixRef <- a ref to a hash of true discoveries
#         $rowRanksRef <- a ref to a hash of arrays of ranked predictions. 
#                         Each hash key is a cui,  each hash element is an 
#                         array of ranked predictions for that cui. The ranked 
#                         predictions are cuis are ordered in descending order 
#                         based on association. (from Rank::RankDescending)
# output: \%meanPrecision <- a hash of mean preicsions at K, each key is the 
#                            value of k, the the value is the precision at that
#                            k
sub calculatePrecisionAtK {
    #grab the input
    my $trueMatrixRef = shift; # a matrix of true discoveries
    my $rowRanksRef = shift; # a hash of ranked predicted discoveries
  
    #generate precision at k at intervals of 10 for k = 10-100
    my %meanPrecision = ();
    my $interval = 1;
    for (my $k = 1; $k <= 100; $k+=$interval) {
	$meanPrecision{$k} = 0;

	#average the mean precision over all terms
	foreach my $rowKey (keys %{$trueMatrixRef}) {
	    my $rankedPredictionsRef = ${$rowRanksRef}{$rowKey}; #an array ref of ranked predictions
	    
	    #skip for rows that have no predictions
	    if (!defined $rankedPredictionsRef) {
		next;
	    } 
	    my $trueRef = ${$trueMatrixRef}{$rowKey}; #a list of true discoveries
	    #threshold the interval, so that it does not exceed 
	    # the number of predictions
	    my $interval = $k;
	    if ($k > scalar @{$rankedPredictionsRef}) {
		$interval = scalar @{$rankedPredictionsRef};
	    }

	    #find the number of true positives in the top $interval ranked terms
	    my $truePositiveCount = 0;
	    for (my $rank = 0; $rank < $interval; $rank++) {
		my $cui = ${$rankedPredictionsRef}[$rank];
		if (exists ${$trueRef}{$cui}) {
		    $truePositiveCount++;
		}
	    }

	    #add this precision to the mean precisions at k
	    $meanPrecision{$k} += ($truePositiveCount/$interval);
	}
	#take the mean of the precisions
	$meanPrecision{$k} /= (scalar keys %{$trueMatrixRef});

	#after computing precision at 1-10, change interval to 10
	if ($k == 10) {
	    $interval = 10;
	}
    }

    #return the mean precisions at k
    return \%meanPrecision;
}


# calculates the number of co-occurrences in the gold set of the top ranked 
# k predictions at k at intervals of 1, from k = 1-10 and intervals of 10 
# for 10-100. Co-occurrence counts are averaged over each of the starting terms
# input:  $trueMatrixRef <- a ref to a hash of true discoveries
#         $rowRanksRef <- a ref to a hash of arrays of ranked predictions. 
#                         Each hash key is a cui,  each hash element is an 
#                         array of ranked predictions for that cui. The ranked 
#                         predictions are cuis are ordered in descending order 
#                         based on association. (from Rank::RankDescending)
# output: \%meanCooccurrenceCounts <- a hash of mean preicsions at K, each key 
#                                     is the value of k, the the value is the 
#                                     precision at that k
sub calculateMeanCooccurrencesAtK {
    #grab the input
    my $trueMatrixRef = shift; # a matrix of true discoveries
    my $rowRanksRef = shift; # a hash of ranked predicted discoveries
  
    #generate mean cooccurrences at k at intervals of 10 for k = 10-100
    my %meanCooccurrenceCount = (); #count of the number of co-occurrences for each k
    my $interval = 1;
    for (my $k = 1; $k <= 100; $k+=$interval) {
	$meanCooccurrenceCount{$k} = 0;

	#average the mean co-occurrenes over all terms
	#  the true matrix contains only rows for the cuis being tested 
        #  or in time slicing
	foreach my $rowKey (keys %{$trueMatrixRef}) {
	    my $rankedPredictionsRef = ${$rowRanksRef}{$rowKey}; #an array ref of ranked predictions
	    
	    #skip for rows that have no predictions
	    if (!defined $rankedPredictionsRef) {
		next;
	    } 
	    my $trueRef = ${$trueMatrixRef}{$rowKey}; #a list of true discoveries

	    #threshold the interval, so that it does not exceed 
	    # the number of predictions
	    my $interval = $k;
	    if ($k > scalar @{$rankedPredictionsRef}) {
		$interval = scalar @{$rankedPredictionsRef};
	    }

	    #find the number of true co-occurrence for the top $interval 
	    # ranked terms
	    my $cooccurrenceCount = 0;
	    for (my $rank = 0; $rank < $interval; $rank++) {
		my $cui = ${$rankedPredictionsRef}[$rank];
		if (exists ${$trueRef}{$cui}) {
		    $cooccurrenceCount += ${$trueRef}{$cui};
		}
	    }

	    #add this precision to the mean precisions at k
	    $meanCooccurrenceCount{$k} += $cooccurrenceCount;
	}
	#take the mean of the cooccurrence counts
	$meanCooccurrenceCount{$k} /= (scalar keys %{$trueMatrixRef});

	#after computing cooccurrence counts  at 1-10, change interval to 10
	if ($k == 10) {
	    $interval = 10;
	}
    }

    #return the mean precisions at k
    return \%meanCooccurrenceCount;
}

1;
