# ALBD::Rank
#
# Library module of ranking methods for LBD
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

package Rank;
use strict;
use warnings;

# scores each implicit CUI using an assocation measure, but the input to 
# the association measure is based on linking term counts, rather than
# co-occurrence counts.
# input:  $startingMatrixRef <- ref to the starting matrix
#         $explicitMatrixRef <- ref to the explicit matrix
#         $implicitMatrixRef <- ref to the implicit matrix
#         $measure <- the string of the umls association measure to use
#         $association <- an instance of umls association
# output: a hash ref of scores for each implicit key. (hash{cui} = score)
sub scoreImplicit_ltcAssociation {
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;
    my $measure = shift;
    my $association = shift;

    #bTerms to calculate n1p (number of unique co-occurring terms)
    my %bTerms = ();
    my $rowRef;
    foreach my $rowKey (keys %{$startingMatrixRef}) {
	$rowRef = ${$startingMatrixRef}{$rowKey};
	foreach my $colKey (keys %{$rowRef}) {
	    $bTerms{$colKey} = 1;
	}
    }
    my $n1p = scalar keys %bTerms;

    #get all the cTerms (unique column values in the implicit matrix)
    my %cTerms = ();
    foreach my $rowKey(keys %{$implicitMatrixRef}) {
	$rowRef = ${$implicitMatrixRef}{$rowKey};
	foreach my $colKey (keys %{$rowRef}) {
	    $cTerms{$colKey} = 1;
	}
    }
    #get np1's (number of unique co-occurring terms for a c term)
    my %np1 = ();
    foreach my $bTerm(keys %{$explicitMatrixRef}) {
	$rowRef = ${$explicitMatrixRef}{$bTerm};
	foreach my $cTerm(keys %{$rowRef}) {
	    #only calculate for cTerms that are in the implicit matrix
	    if (exists $cTerms{$cTerm}) {
		#automatically initializes to 0
		$np1{$cTerm}++;
	    }
	}
    }

    #get n11 for each c term
    my %n11 = ();
    foreach my $cTerm (keys %cTerms) {
	$n11{$cTerm} = 0;
	foreach my $bTerm (keys %bTerms) {
	    if (exists ${${$explicitMatrixRef}{$bTerm}}{$cTerm}) {
		$n11{$cTerm}++;
	    }
	}
    }

    #calculate npp as the vocabulary size (TODO or should it be the number 
    #  of connections? (number of keys in the matrix))
    my $npp = 0;
    my %uniqueKeys = ();
    foreach my $key1 (keys %{$explicitMatrixRef}) {
	$rowRef = ${$explicitMatrixRef}{$key1};
	foreach my $key2 (keys %{$rowRef}) {
	    $uniqueKeys{$key2} = 1;
	}
    }
    $npp = scalar keys %uniqueKeys;

    #get scores for each cTerm
    my %score = ();
    foreach my $cTerm (keys %cTerms) {
	#assume calculation cannot be made
	$score{$cTerm} = -1;
	
	#only calculate if np1 > 0
	if ($np1{$cTerm} > 0) {
	    #get score
	    $score{$cTerm} = $association->_calculateAssociation_fromObservedCounts($n11{$cTerm}, $n1p, $np1{$cTerm}, $npp, $measure);
	}
    }
    
    return \%score;
}


# scores each implicit CUI using an assocation measure. Score is the average
# of the minimum between association score between start and linking, and
# linking and target.
# input:  $startingMatrixRef <- ref to the starting matrix
#         $explicitMatrixRef <- ref to the explicit matrix
#         $implicitMatrixRef <- ref to the implicit matrix
#         $measure <- the string of the umls association measure to use
#         $association <- an instance of umls association
#         $abScoresRef <- hashRef of the a to b scores used in AMW
#                         key is the a,b cui pair (e.g. hash{'C00,C11'})
#                         values are their score
#
#         Optional Input for passing in precalculated stats
#         so that they don't have to get recalcualted each time
#         such as in timeslicing
#         $n1pRef <- hashRef where key is a cui, value is n1p
#         $np1Ref <- hashRef where key is a cui, value is np1
#         $npp <- scalar = value of npp
# output: a hash ref of scores for each implicit key. (hash{cui} = score)
sub scoreImplicit_averageMinimumWeight {
    #grab input
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;
    my $measure = shift;
    my $association = shift;
    my $abScoresRef = shift;

    #optionally pass in stats so they don't get recalculated for
    # multiple terms (such as with time slicing)
    my $n1pRef = shift;
    my $np1Ref = shift;
    my $npp = shift;

    #get all BC pairs (call it bcScores because it will hold the scores)
    my $bcScoresRef = &_getBCPairs($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef);

    #get cui pair scores
    &getBatchAssociationScores(
	$bcScoresRef, $explicitMatrixRef, $measure, $association,
	$n1pRef, $np1Ref, $npp);

    #find the max a->b score (since there can be multiple a terms)
    my %maxABScores = ();
    my ($key1, $key2, $score);
    foreach my $pairKey (keys %{$abScoresRef}) {
	 #second value is b term
	($key1, $key2) = split(/,/,$pairKey);
	$score = ${$abScoresRef}{$pairKey};

	if ($score != -1) { #only compute for associations that exist
	    if (exists $maxABScores{$key2}) {
		if ($score > $maxABScores{$key2}) {
		    $maxABScores{$key2} = $score;
		}
	    } else {
		$maxABScores{$key2} = $score;
	    }
	}
    }

    # Find the average minimum weight (cScores) for each c term
    # average of minimum a->b score and b->c score
    my %cScores = ();
    my %counts = ();
    my ($value, $count, $min, $bTerm, $cTerm);
    #sum min scores
    foreach my $pairKey (keys %{$bcScoresRef}) {

	#only compute for scores that exist
	if (${$bcScoresRef}{$pairKey} != -1) {
	    #first is bTerm, second is cTerm
	    ($bTerm, $cTerm) = split(/,/,$pairKey);
	    
	    #check there is an AB value
	    if ($maxABScores{$bTerm} != -1) {  

		#get the minimum between a->b and b->c
		$min = ${$bcScoresRef}{$pairKey};  
		if ($maxABScores{$bTerm} < $min) {
		    $min = $maxABScores{$bTerm};
		}

		#increase the sum (automatically initialize to 0)
		$cScores{$cTerm} += $min;
		$counts{$cTerm}++; 
	    }
	}
    }
    #normalize by counts
    foreach my $key (keys %cScores) {
	$cScores{$key} /= $counts{$key}
    }
 
    return \%cScores;
}


# scores each implicit CUI using linking term count, and AMW as a tie breaker
# input:  $startingMatrixRef <- ref to the starting matrix
#         $explicitMatrixRef <- ref to the explicit matrix
#         $implicitMatrixRef <- ref to the implicit matrix
#         $measure <- the string of the umls association measure to use
#         $association <- an instance of umls association
#         $abScoresRef <- hashRef of the a to b scores used in AMW
#                         key is the a,b cui pair (e.g. hash{'C00,C11'})
#                         values are their score
#         Optional Input for passing in precalculated stats
#         so that they don't have to get recalcualted each time
#         such as in timeslicing
#         $n1pRef <- hashRef where key is a cui, value is n1p
#         $np1Ref <- hashRef where key is a cui, value is np1
#         $npp <- scalar = value of npp
# output: a hash ref of scores for each implicit key. (hash{cui} = score)
sub scoreImplicit_LTC_AMW {
    #grab the input
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;
    my $measure = shift;
    my $association = shift;
    my $abScoresRef = shift;

    #optionally pass in stats so they don't get recalculated for
    # multiple terms (such as with time slicing)
    my $n1pRef = shift;
    my $np1Ref = shift;
    my $nppRef = shift;

    #get linking term count scores
    my $ltcAssociationsRef = &scoreImplicit_linkingTermCount($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef);

    #get average minimum weight scores
    my $amwScoresRef = &scoreImplicit_averageMinimumWeight($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef, $measure, $association, $abScoresRef, $n1pRef, $np1Ref, $nppRef); 

    #create a hash of cui pairs for which the key is the ltc, and the value is an array of cui pairs that have that LTC
    my %ltcHash = ();
    foreach my $pairKey (keys %{$ltcAssociationsRef}) {
		
	#get the LTC we will be tie breaking
	my $currentLTC = ${$ltcAssociationsRef}{$pairKey};
	if (!exists $ltcHash{$currentLTC}) {
	    my @newArray = ();
	    $ltcHash{$currentLTC} = \@newArray;
	}
	push @{$ltcHash{$currentLTC}}, $pairKey;
    }

    #generate the LTC-AMW scores by assigning a rank value
    # first by LTC, and then my AMW
    my %ltcAMWScores = ();
    my $topRank = scalar keys %{$ltcAssociationsRef};
    my $currentRank = $topRank;
    #iterate first over ltc in descending order
    foreach my $ltc (sort {$b <=> $a} keys %ltcHash) {

	#check each cuiPair with this ltc
	my %tiedAMWScores = ();
	foreach my $cuiPair (@{$ltcHash{$ltc}}) {
	    $tiedAMWScores{$cuiPair} = ${$amwScoresRef}{$cuiPair};
	}

	#add the cui pairs by descending amw score
	foreach my $cuiPair (sort {$tiedAMWScores{$b} <=> $tiedAMWScores{$a}} keys %tiedAMWScores) {
	    $ltcAMWScores{$cuiPair} = $currentRank;
	    $currentRank--;
	}
    }

    #return the scores
    return \%ltcAMWScores;
}

#TODO this is an untested method
# gets the max cosine distance score between all a terms and each cTerm 
# input:  $startingMatrixRef <- ref to the starting matrix
#         $explicitMatrixRef <- ref to the explicit matrix
#         $implicitMatrixRef <- ref to the implicit matrix
# output: a hash ref of scores for each implicit key. (hash{cui} = score)
sub score_cosineDistance {
    #LBD Info
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;

    #get all the A->C pairs
    my $acPairsRef = &_getACPairs($startingMatrixRef, $implicitMatrixRef);
    my %scores = ();
    foreach my $pairKey (keys %{$acPairsRef}) {
	#get the A and C keys
	my ($aKey, $cKey) = split(/,/,$pairKey);

	#grab the A and C explicit vectors
	my $aVectorRef = ${$explicitMatrixRef}{$aKey};
	my $cVectorRef = ${$explicitMatrixRef}{$cKey};

	#find the numerator which is the sum of A[i]*C[i] values
	my $numerator = 0;
	foreach my $key (keys ${$aVectorRef}) {
	    if (exists ${$cVectorRef}{$key}) {
		$numerator += ${$aVectorRef}{$key} * ${$cVectorRef}{$key};
	    }
	}

	#find the sum of A squared
	my $aSum = 0;
	foreach my $key (keys ${$aVectorRef}) {
	    $aSum += ($key*$key);
	}

	#find the sum of C squared
	my $cSum = 0;
	foreach my $key (keys ${$aVectorRef}) {
	    $cSum += ($key*$key);
	}

	#find the denominator, which is the product of A and C lengths
	my $denom = sqrt($aSum)*sqrt($cSum);

	#set the score (maximum score seen for that C term)
	my $score = -1;
	if ($denom != 0) {
	    $score = $numerator/$denom;
	}
	if (exists $scores{$cKey}) {
	    if ($score > $scores{$cKey}) {
		$scores{$cKey} = $score;
	    }
	}
	else {
	    $scores{$cKey} = $score;
	}	
    }
    
    return \%scores;
}

# gets a list of A->C pairs, and sets the value as the implicit matrix value
# input:  $startingMatrixRef <- ref to the starting matrix
#         $implicitMatrixRef <- ref to the implicit matrix
# output: a hash ref where keys are comma seperated cui pairs hash{'C000,C111'}
#         and values are set to the value at that index in the implicit matrix
sub _getACPairs {
    my $startingMatrixRef = shift;
    my $implicitMatrixRef = shift;

    #generate a list of ac pairs
    my %acPairs = ();
    foreach my $keyA (keys %{$implicitMatrixRef}) {
	foreach my $keyC (%{${$implicitMatrixRef}{$keyA}}) {
	    $acPairs{$keyA,$keyC} = ${${$implicitMatrixRef}{$keyA}}{$keyC};
	}
    }
    
    return \%acPairs;

}


# scores each implicit CUI based on the number of linking terms between
# it and all starting terms.
# input:  $startingMatrixRef <- ref to the starting matrix
#         $explicitMatrixRef <- ref to the explicit matrix
#         $implicitMatrixRef <- ref to the implicit matrix
# output: a hash ref of scores for each implicit key. (hash{cui} = score)
sub scoreImplicit_linkingTermCount {
    #LBD Info
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;

    #get all bc pairs
    my $bcPairsRef = &_getBCPairs($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef);

    # Find the linking term count for each cTerm
    my %scores = ();
    my ($key1, $key2);
    foreach my $pairKey (keys %{$bcPairsRef}) {
	#cTerm is the second value ($key2)
	($key1, $key2) = split(/,/,$pairKey);

	#automatically initializes to 0
	$scores{$key2}++;
    }
    return \%scores;
}


# scores each implicit CUI based on the summed frequency of co-occurrence
# between it and all B terms (A->B frequencies are NOT considered)
# input:  $startingMatrixRef <- ref to the starting matrix
#         $explicitMatrixRef <- ref to the explicit matrix
#         $implicitMatrixRef <- ref to the implicit matrix
# output: a hash ref of scores for each implicit key. (hash{cui} = score)
sub scoreImplicit_frequency {
    #LBD Info
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;

    #get all bc pairs
    my $bcPairsRef = &_getBCPairs($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef);

    # Find the frequency count for each cTerm
    my %scores = ();
    my ($key1, $key2);
    foreach my $pairKey (keys %{$bcPairsRef}) {
	#cTerm is the second value ($key2)
	($key1, $key2) = split(/,/,$pairKey);

	#automatically initializes to 0 (with +=)
	$scores{$key2} += ${$bcPairsRef}{$pairKey};
    }
    return \%scores;
}

# scores each implicit CUI using an assocation measure. Score is the maximum 
# association between a column in the implicit matrix, and one of the start 
# matrix terms (so max between any A and that C term). 
# Score is calculated using the implicit matrix
# input:  $startCuisRef <- ref to an array of start cuis (A terms)
#         $implicitMatrixFileName <- fileName of the implicit matrix
#         $measure <- the string of the umls association measure to use
#         $association <- an instance of umls association
# output: a hash ref of scores for each implicit key. (hash{cui} = score)
sub scoreImplicit_fromImplicitMatrix {
    #LBD Info
    my $startCuisRef = shift;
    my $implicitMatrixFileName = shift;
    my $measure = shift;
    my $association = shift;

######################################
    #Get hashes for A and C terms
#####################################
    #create a hash of starting terms
    my %aTerms = ();
    foreach my $cui (@{$startCuisRef}) {
	$aTerms{$cui} = 1;
    }

    #get all the target terms (terms that co-occur with aTerms 
    # in the implicit matrix file = the implicit terms)
    open IN, "$implicitMatrixFileName";
    my %cTerms = ();
    while (my $line = <IN>) {
	$line =~ /(C\d{7})\s(C\d{7})/;
	if (exists $aTerms{$1}) {
	    $cTerms{$2} = 1;
	}
    }

######################################
    #Get Co-occurrence values, N11, N1P, NP1, NPP
######################################
    #NPP is the number of Co-occurreces total
    #@NP1 is the number of co-occurrences of a C term with any term ... so sum of XXX\tCTerm\tVal for each cTerm
    #@N1P is the number of co-occurrences of any A term ... so sum of anyATerm\tXXX\t
    #N11{Cterm} is the sum of anyATerm\tCTerm\tVal
    seek IN, 0,0; #reset to the beginning of the implicit file

    #iterate over the lines of interest, and grab values
    my %np1 = ();
    my %n11 = ();
    my $n1p = 0;
    my $npp = 0;
    my $matchedCuiB = 0;
    my ($cuiA, $cuiB, $val);
    while (my $line = <IN>) {
	#grab data from the line
	($cuiA, $cuiB, $val) = split(/\t/,$line);

	#see if updates are necessary
	if (exists $aTerms{$cuiA} || exists $cTerms{$cuiB}) {

	    #update npp
	    $npp += $3;
	    
	    #update np1
	    if (exists $cTerms{$cuiB}) {
		$np1{$cuiB} += $val;
		$matchedCuiB = 1;
	    }

	    #update n1p
	    if (exists $aTerms{$cuiA}) {
		$n1p += $val;

		#update n11 if needed
		if ($matchedCuiB) {
		    $n11{$cuiB} += $val;
		    $matchedCuiB = 0;
		}
	    }
	}
    }


######################################
    # Calculate Association for each c term
######################################
    my %associationScores = ();
    foreach my $cTerm(keys %cTerms) {
	$associationScores{$cTerm} = 
	    $association->_calculateAssociation_fromObservedCounts($n11{$cTerm}, $n1p, $np1{$cTerm}, $npp, $measure);
    }

    return \%associationScores;
}

# scores each implicit CUI using an assocation measure. Score is the maximum 
# association between any of the linking terms.
# input:  $startingMatrixRef <- ref to the starting matrix
#         $explicitMatrixRef <- ref to the explicit matrix
#         $implicitMatrixRef <- ref to the implicit matrix
#         $measure <- the string of the umls association measure to use
#         $association <- an instance of umls association
# output: a hash ref of scores for each implicit key. (hash{cui} = score)
sub scoreImplicit_fromAllPairs {
    #LBD Info
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;
    my $measure = shift;
    my $association = shift;

    #optionally pass in stats so they don't get recalculated for
    # multiple terms (such as with time slicing)
    my $n1pRef = shift;
    my $np1Ref = shift;
    my $npp = shift;

    #get all bc pairs
    my $bcPairsRef = &_getBCPairs($startingMatrixRef, 
				  $explicitMatrixRef, $implicitMatrixRef);

    #get bc pairs scores
    &getBatchAssociationScores(
	$bcPairsRef, $explicitMatrixRef, $measure, $association,
	$n1pRef, $np1Ref, $npp);


    # Find the max explicitCUI,implicitCUI association for each implicit CUI. 
    # The association score is the maximum value between a C term and all 
    # B terms
    my %scores = ();
    my $max;
    my $value;
    my $implicitCui;
    my ($key1,$key2);
    foreach my $pairKey (keys %{$bcPairsRef}) {	

	#only compare association scores that are valid
	if (${$bcPairsRef}{$pairKey} != -1) {
	    ($key1,$key2) = split(/,/,$pairKey);
	    #only use key2, since that is the implicit cui (c term)

	    #update max for this implicit cui or create if needed
	    if (!exists $scores{$key2}) {
		$scores{$key2} = ${$bcPairsRef}{$pairKey};
	    }
	    elsif (${$bcPairsRef}{$pairKey} > $scores{$key2}) {
		$scores{$key2} = ${$bcPairsRef}{$pairKey}
	    }
	}
    }
    
    return \%scores;
}


sub scoreImplicit_minimumWeightAssociation {

}


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX



# Builds a list of B->C term pairs that also co-occurr with A terms
# Only adds B->C term pairs for C terms that are also present in the 
# implicitMatrix.
# The value of the bcPairs Hash is the value in the explicit matrix 
# for that pair.
# input:  $startingMatrixRef <- ref to the starting matrix
#         $explicitMatrixRef <- ref to the explicit matrix
#         $implicitMatrixRef <- ref to the implicit matrix
# output: a hash ref of BC term pairs. Each key is "$bTerm,$cTerm", 
#         value is by default the frequency of BC co-occurrences in the 
#         matrix
sub _getBCPairs {
    my $startingMatrixRef = shift;
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;

    #get all bTerms
    my %bTerms = ();
    my $rowRef;
    foreach my $rowKey (keys %{$startingMatrixRef}) {
	$rowRef = ${$startingMatrixRef}{$rowKey};
	foreach my $colKey (keys %{$rowRef}) {
	    $bTerms{$colKey} = 1;
	}
    }

    #get all the cTerms (unique column values in the implicit matrix)
    my %cTerms = ();
    foreach my $rowKey(keys %{$implicitMatrixRef}) {
	$rowRef = ${$implicitMatrixRef}{$rowKey};
	foreach my $colKey (keys %{$rowRef}) {
	    $cTerms{$colKey} = 1;
	}
    }

    #get all bc pairs, set value to be the frequency of co-occurrence
    my %bcPairs = ();
    foreach my $bTerm(keys %bTerms) {
	$rowRef = ${$explicitMatrixRef}{$bTerm};
	if ($rowRef) {
	    foreach my $cTerm(keys %{$rowRef}) {
		if (exists $cTerms{$cTerm}) {
		    #add because this a->b->c term (%cTerms) is also a b->c term
		    $bcPairs{"$bTerm,$cTerm"} = ${$rowRef}{$cTerm};
		}
	    }
	}
    }
    return \%bcPairs;
}


# ranks the scores in descending order
# input: $scoresRef <- a hash ref to a hash of cuis and scores (hash{cui} = score)
# output: an array ref of the ranked cuis in descending order
sub rankDescending {
    #grab the input
    my $scoresRef = shift;

    #order in descending order, and use the CUI string as a tiebreaker
    my @rankedCuis = ();
    my @tiedCuis = ();
    my $currentScore = -1;
    foreach my $cui (
	#sort function to sort by value
	sort {${$scoresRef}{$b} <=> ${$scoresRef}{$a}} 
	keys %{$scoresRef}) {

	#see if this cui is tied with previuos
	if (${$scoresRef}{$cui} != $currentScore) {
	    #this cui is not tied with previuos,
	    # so save all previuos ones to the ranked array
	    # Here, we sort by key name, so the tie breaker
	    # is the cui name itself. This is arbitrary but 
	    # allows for results to be precisely replicated.
	    # UPDATE: Almost precisely replicated. There is 
	    # a numerical stability problem so that the sort
	    # by value will chunk out differently depending 
	    # on the run. So one run something with a values of 
	    # 0.66666666666667 will be sorted above another item
	    # with that same value, the next run sorted with it.
	    # this is essentially unavoidable without implementing
	    # a tolerance threshold which seems like overkill
	    foreach my $tiedCui (sort @tiedCuis) {
		push @rankedCuis, $tiedCui;
	    }

	    #clear the list of tied CUIs
	    @tiedCuis = ();
	}
	#add current CUI to the tied CUI list and update the
	# current score
	$currentScore = ${$scoresRef}{$cui};
	push @tiedCuis, $cui;
    }
    #add any remaining tied cuis to the final list
    foreach my $cui (sort @tiedCuis) {
	push @rankedCuis, $cui;
    }

    #return the ranked cuis
    return \@rankedCuis;
}


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# gets association scores for a set of cui pairs 
# input:  $cuiPairsRef <- reference to a hash of pairs of matrix indeces (key = '1,2')
#         $matrixRef <- a reference to a sparse matrix of n11 values
#         $measure <- the association measure to perform
#         $association <- an instance of UMLS::Association
# output: none, bu the cuiPairs ref has values updated to reflect the 
#         computed assocation score
sub getBatchAssociationScores {
    my $cuiPairsRef = shift;
    my $matrixRef = shift;
    my $measure = shift;
    my $association = shift;
    
    #optionally pass in $n1pRef, $np1Ref, and $npp
    # do this if they get calculated multiple times
    # (such as with time slicing)
    my $n1pRef = shift;
    my $np1Ref = shift;
    my $npp = shift;

    #if the measure is frequency, you only need to return 
    # the cuiPairs ref which already holds CUI frequencies
    if ($measure eq 'freq') {
	return $cuiPairsRef;
    }

    #calculate stats if needed
    if (!defined $n1pRef || !defined $np1Ref || !defined $npp) {
	($n1pRef, $np1Ref, $npp) = &getAllStats($matrixRef);
    }
    
    #get association scores for each CUI pair
    my ($n11, $cui1, $cui2);
    foreach my $key (keys %{$cuiPairsRef}) {
	#get the cui indeces
	($cui1, $cui2) = split(/,/,$key);

	#assume calculation cannot be made
	${$cuiPairsRef}{$key} = -1;

	#get n11
	$n11 = ${${$matrixRef}{$cui1}}{$cui2};

	#get association if possible (only possible if the terms have co-occurred)
	if (defined $n11) {
	    ${$cuiPairsRef}{$key} = $association->_calculateAssociation_fromObservedCounts($n11, ${$n1pRef}{$cui1}, ${$np1Ref}{$cui2}, $npp, $measure);
	}
    }
}

# gets NP1, N1P, and NPP for all CUIs. This is used in time-
# slicing and makes it much faster than getting stats individually
# for each starting term
# input:  $matrixRef <- ref to the co-occurrence matrix (the sparse matrix 
#                       of n11 values)
# output: \@vals <- an array ref of three values:
#                   \%n1p - a hash ref where the key is a cui and value is n1p
#                   \%np1 - a hash ref where the key is a cui and value is np1
#                   $npp - a scalar of npp
sub getAllStats {
    my $matrixRef = shift;

    #get all np1, n1p, and npp values of values for each cui
    my %np1 = ();
    my %n1p = ();
    my $npp = 0;
    my $val;
    foreach my $key1 (keys %{$matrixRef}) {
	foreach my $key2 (keys %{${$matrixRef}{$key1}}) {
	    $val = ${${$matrixRef}{$key1}}{$key2};
	    $n1p{$key1} += $val;
	    $np1{$key2} += $val;
	    $npp += $val;
	}
    }

    return (\%n1p, \%np1, $npp);
}


1;
