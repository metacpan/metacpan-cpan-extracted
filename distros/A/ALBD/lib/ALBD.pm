# ALBD::ALBD
#
# Primary module
# This module contains only the top level functions. So a step by step methods
# Filtering, everything else is in different modules. 
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


=head1 NAME

ALBD - a perl implementation of Literature Based Discovery

=head1 SYNOPSIS
    
    use ALBD;
    %options = ();
    $options{'lbdConfig'} = 'configFile'
    my $lbd = LiteratureBasedDiscovery->new(\%options);
    $lbd->performLBD();

=head1 ABSTRACT

      This package consists of Perl modules along with supporting Perl
      programs that perform Literature Based Discovery (LBD). The core 
      data from which LBD is performed are co-occurrences matrices 
      generated from UMLS::Association. ALBD is based on the ABC
      co-occurrence model. Many options can be specified, and many
      ranking methods are available. The novel ranking methods that use
      association measure are available as well as frequency based
      ranking methods. See samples/lbd for more info. Can perform open and
      closed LBD as well as time slicing evaluation.

=head1 INSTALL

To install the module, run the following magic commands:

  perl Makefile.PL
  make
  make test
  make install

This will install the module in the standard location. You will, most
probably, require root privileges to install in standard system
directories. To install in a non-standard directory, specify a prefix
during the 'perl Makefile.PL' stage as:

  perl Makefile.PL PREFIX=/home/sid

It is possible to modify other parameters during installation. The
details of these can be found in the ExtUtils::MakeMaker
documentation. However, it is highly recommended not messing around
with other parameters, unless you know what you're doing.

=head1 CONFIGURATION FILE

There are many parameters that can be specified, both for open and
close discovery as well as time slicing evaluation. Please see the 
samples folder for info and sample configuration files.

=cut


######################################################################
#                          Description
######################################################################
#
# This is a description heared more towards understanding or modifying
# the code, rather than using the program.
#
# LiteratureBasedDiscovery.pm - provides functionality to perform LBD
#
# Matrix Representation:
# LBD is performed using Matrix and Vector operations. The major components 
# are an explicit knowledge matrix, which is squared to find the implicit 
# knowledge matrix.
#
# The explicit knowledge is read from UMLS::Association N11 matrix. This 
# matrix contains the co-occurrence counts for all CUI pairs. The 
# UMLS::Association database is completely independent from 
# implementation, so any dataset, window size, or anything else may be used. 
# Data is read in as a sparse matrix using the Discovery::tableToSparseMatrix 
# function. This returns the primary data structures and variables used 
# throughtout LBD.
#
# Matrix representation: 
# This module uses a matrix representation for LBD. All operations are 
# performed either as matrix or vector operations. The core data structure
# are the co-occurrence matrices explicitMatrix and implicitMatrix. These
# matrices have dimensions vocabulary size by vocabulary size. Each row 
# corresponds to the all co-occurrences for a single CUI. Each column of that 
# row corresponding to a co-occurrence with a single CUI. Since the matrices 
# tend to be sparse, they are stored as hashes of hashes, where the the first 
# key is for a row, and the second key is for a column. The keys of each hash 
# are the indeces within the matrix. The hash values are the number of 
# co-ocurrences for that CUI pair (e.g. ${${$explicit{C0000000}}{C1111111} = 10 
# means that CUI C0000000 and C1111111 co-occurred 10 times).
#
# Now with an understanding of the data strucutres, below is a breif 
# description of each: 
#
# startingMatrix <- A matrix containing the explicit matrix rows for all of the
#                   start terms. This makes it easy to have multiple start terms
#                   and using this matrix as opposed to the entire explicit 
#                   matrix drastically improves performance.
# explicitMatrix <- A matrix containing explicit connections (known connections)
#                   for every CUI in the dataset.            
# implicitMatrix <- A matrix containing implicit connections (discovered 
#                   connections) for every CUI in the datast


package ALBD;

use strict;
use warnings;

use LiteratureBasedDiscovery::Discovery;
use LiteratureBasedDiscovery::Evaluation;
use LiteratureBasedDiscovery::Rank;
use LiteratureBasedDiscovery::Filters;
use LiteratureBasedDiscovery::TimeSlicing;

use UMLS::Association;
use UMLS::Interface;

#### UPDATE VERSION HERE #######
use vars qw($VERSION);
$VERSION = 0.05;

#global variables
my $DEBUG = 0;
my $N11_TABLE = 'N_11';
my %lbdOptions = ();
   #rankingProcedure <-- the procedure to use for ranking
   #rankingMeasure <-- the association measure to use for ranking 
   #implicitOutputFile  <--- the output file of results
   #explicitInputFile <-- file to load explicit matrix from
   #implicitInputFile <-- load implicit from file rather than calculating

#references to other packages
my $umls_interface;
my $umls_association;

#####################################################
####################################################

# performs LBD
# input:  none
# ouptut: none, but a results file is written to disk
sub performLBD {
    my $self = shift;
    my $start; #used to record run times

    #implicit matrix ranking requires a different set of procedures
    if ($lbdOptions{'rankingProcedure'} eq 'implicitMatrix') { 
	$self->performLBD_implicitMatrixRanking();
	return;
    }
    if (exists $lbdOptions{'targetCuis'}) {
	$self->performLBD_closedDiscovery();
	return;
    }
    if (exists $lbdOptions{'precisionAndRecall_explicit'}) {
	$self->timeSlicing_generatePrecisionAndRecall_explicit();
	return;
    }
    if (exists $lbdOptions{'precisionAndRecall_implicit'}) {
	$self->timeSlicing_generatePrecisionAndRecall_implicit();
	return;
    }
    print "Open Discovery\n";
    print $self->_parametersToString();

#Get inputs
    my $startCuisRef = $self->_getStartCuis();
    my $linkingAcceptTypesRef = $self->_getAcceptTypes('linking');
    my $targetAcceptTypesRef = $self->_getAcceptTypes('target');
    print "startCuis = ".(join(',', @{$startCuisRef}))."\n";
    print "linkingAcceptTypes = ".(join(',', keys %{$linkingAcceptTypesRef}))."\n";
    print "targetAcceptTypes = ".(join(',', keys %{$targetAcceptTypesRef}))."\n";

#Get the Explicit Matrix
    $start = time;
    my $explicitMatrixRef;
    if(!defined $lbdOptions{'explicitInputFile'}) {
	die ("ERROR: explicitInputFile must be defined in LBD config file\n");
    }
    $explicitMatrixRef = Discovery::fileToSparseMatrix($lbdOptions{'explicitInputFile'});
    print "Got Explicit Matrix in ".(time() - $start)."\n";
    
#Get the Starting Matrix
    $start = time();
    my $startingMatrixRef = 
	Discovery::getRows($startCuisRef, $explicitMatrixRef);
    print "Got Starting Matrix in ".(time() - $start)."\n";

    #if using average minimum weight, grab the a->b scores
    my %abPairsWithScores = ();
    if ($lbdOptions{'rankingProcedure'} eq 'averageMinimumWeight' 
	|| $lbdOptions{'rankingProcedure'} eq 'ltc_amw') {

	#apply semantic type filter to columns only
	if ((scalar keys %{$linkingAcceptTypesRef}) > 0) {
	    Filters::semanticTypeFilter_columns(
		$explicitMatrixRef, $linkingAcceptTypesRef, $umls_interface);
	}
	#initialize the abPairs to frequency of co-occurrence
	foreach my $row (keys %{$startingMatrixRef}) {
	    foreach my $col (keys %{${$startingMatrixRef}{$row}}) {
		$abPairsWithScores{"$row,$col"} = ${${$startingMatrixRef}{$row}}{$col};
	    }
	}
        Rank::getBatchAssociationScores(\%abPairsWithScores, $explicitMatrixRef, $lbdOptions{'rankingMeasure'}, $umls_association);
    }

    #Apply Semantic Type Filter to the explicit matrix
    if ((scalar keys %{$linkingAcceptTypesRef}) > 0) {
	$start = time();
	Filters::semanticTypeFilter_rowsAndColumns(
	    $explicitMatrixRef, $linkingAcceptTypesRef, $umls_interface);
	print "Semantic Type Filter in ".(time() - $start)."\n";
    }
    
#Get Implicit Connections
    $start = time();
    my $implicitMatrixRef;
    if (defined $lbdOptions{'implicitInputFile'}) {
	$implicitMatrixRef = Discovery::fileToSparseMatrix($lbdOptions{'implicitInputFile'});
    } else {
	$implicitMatrixRef = Discovery::findImplicit($explicitMatrixRef, $startingMatrixRef);
    }
    print "Got Implicit Matrix in ".(time() - $start)."\n";

#Remove Known Connections 
     $start = time();
     $implicitMatrixRef = Discovery::removeExplicit($startingMatrixRef, $implicitMatrixRef);
     print "Removed Known Connections in ".(time() - $start)."\n";
 
#Apply Semantic Type Filter
    if ((scalar keys %{$targetAcceptTypesRef}) > 0) {
	$start = time();
	Filters::semanticTypeFilter_columns(
	    $implicitMatrixRef, $targetAcceptTypesRef, $umls_interface);
	print "Semantic Type Filter in ".(time() - $start)."\n";
    }

#Score Implicit Connections
    $start = time();	
    my $scoresRef;
    if ($lbdOptions{'rankingProcedure'} eq 'allPairs') {
	$scoresRef = Rank::scoreImplicit_fromAllPairs($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef, $lbdOptions{'rankingMeasure'}, $umls_association);
    } elsif ($lbdOptions{'rankingProcedure'} eq 'averageMinimumWeight') {
	$scoresRef = Rank::scoreImplicit_averageMinimumWeight($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef, $lbdOptions{'rankingMeasure'}, $umls_association, \%abPairsWithScores);
    } elsif ($lbdOptions{'rankingProcedure'} eq 'linkingTermCount') {
	$scoresRef = Rank::scoreImplicit_linkingTermCount($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef);
    } elsif ($lbdOptions{'rankingProcedure'} eq 'frequency') {
	$scoresRef = Rank::scoreImplicit_frequency($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef);
    } elsif ($lbdOptions{'rankingProcedure'} eq 'ltcAssociation') {
	$scoresRef = Rank::scoreImplicit_ltcAssociation($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef, $lbdOptions{'rankingMeasure'}, $umls_association);
    } elsif ($lbdOptions{'rankingProcedure'} eq 'ltc_amw') {
	$scoresRef = Rank::scoreImplicit_LTC_AMW($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef, $lbdOptions{'rankingMeasure'}, $umls_association, \%abPairsWithScores);
    } else {
	die ("Error: Invalid Ranking Procedure\n");
    }    
    print "Scored in: ".(time()-$start)."\n";
  
#Rank Implicit Connections
    $start = time();
    my $ranksRef = Rank::rankDescending($scoresRef);
    print "Ranked in: ".(time()-$start)."\n";

#Output The Results
    open OUT, ">$lbdOptions{implicitOutputFile}" 
	or die "unable to open implicit ouput file: "
	."$lbdOptions{implicitOutputFile}\n";
    my $outputString = $self->_rankedTermsToString($scoresRef, $ranksRef);
    my $paramsString = $self->_parametersToString();
    print OUT $paramsString;
    print OUT $outputString;
    close OUT;

#Done
    print "DONE!\n\n";
}

#----------------------------------------------------------------------------

# performs LBD, closed discovery
# input:  none
# ouptut: none, but a results file is written to disk
sub performLBD_closedDiscovery {
    my $self = shift;
    my $start; #used to record run times

    print "Closed Discovery\n";
    print $self->_parametersToString();

#Get inputs
    my $startCuisRef = $self->_getStartCuis();
    my $targetCuisRef = $self->_getTargetCuis();
    my $linkingAcceptTypesRef = $self->_getAcceptTypes('linking');

#Get the Explicit Matrix
    $start = time;
    my $explicitMatrixRef;
    if(!defined $lbdOptions{'explicitInputFile'}) {
	die ("ERROR: explicitInputFile must be defined in LBD config file\n");
    }
    $explicitMatrixRef = Discovery::fileToSparseMatrix($lbdOptions{'explicitInputFile'});
    print "Got Explicit Matrix in ".(time() - $start)."\n";
    
#Get the Starting Matrix
    $start = time();
    my $startingMatrixRef = 
	Discovery::getRows($startCuisRef, $explicitMatrixRef);
    print "Got Starting Matrix in ".(time() - $start)."\n";
    print "   numRows in startMatrix = ".(scalar keys %{$startingMatrixRef})."\n";

    #Apply Semantic Type Filter to the explicit matrix
    if ((scalar keys %{$linkingAcceptTypesRef}) > 0) {
	$start = time();
	Filters::semanticTypeFilter_rowsAndColumns(
	    $explicitMatrixRef, $linkingAcceptTypesRef, $umls_interface);
	print "Semantic Type Filter in ".(time() - $start)."\n";
    }

#Get the Target Matrix
    $start = time();
    my $targetMatrixRef = 
	Discovery::getRows($targetCuisRef, $explicitMatrixRef);
    print "Got Target Matrix in ".(time() - $start)."\n";
    print "   numRows in targetMatrix = ".(scalar keys %{$targetMatrixRef})."\n";

#find the linking terms in common for starting and target matrices
    print "Finding terms in common\n";
    #get starting linking terms
    my %startLinks = ();
    foreach my $row (keys %{$startingMatrixRef}) {
	foreach my $col (keys %{${$startingMatrixRef}{$row}}) {
	    $startLinks{$col} = ${${$startingMatrixRef}{$row}}{$col};
	}
    }
    print "   num start links = ".(scalar keys %startLinks)."\n";
    #get target linking terms
    my %targetLinks = ();
    foreach my $row (keys %{$targetMatrixRef}) {
	foreach my $col (keys %{${$targetMatrixRef}{$row}}) {
	    $targetLinks{$col} = ${${$targetMatrixRef}{$row}}{$col};
	}
    }
    print "   num target links = ".(scalar keys %targetLinks)."\n";
    #find linking terms in common
    my %inCommon = ();
    foreach my $startLink (keys %startLinks) {
	if (exists $targetLinks{$startLink}) {
	    $inCommon{$startLink} = $startLinks{$startLink} + $targetLinks{$startLink};
	}
    }
     print "   num in common = ".(scalar keys %inCommon)."\n";

#Score and Rank
    #Score the linking terms in common
    my $scoresRef = \%inCommon;
    #TODO score is just summed frequency right now

    #Rank Implicit Connections
    $start = time();
    my $ranksRef = Rank::rankDescending($scoresRef);
    print "Ranked in: ".(time()-$start)."\n";

#Output The Results
    open OUT, ">$lbdOptions{implicitOutputFile}" 
	or die "unable to open implicit ouput file: "
	."$lbdOptions{implicitOutputFile}\n";
    my $outputString = $self->_rankedTermsToString($scoresRef, $ranksRef);
    my $paramsString = $self->_parametersToString();
    print OUT $paramsString;
    print OUT $outputString;

    print OUT "\n\n---------------------------------------\n\n";
    print OUT "starting linking terms:\n";
    print OUT join("\n", keys %startLinks);

    print OUT "\n\n---------------------------------------\n\n";
    print OUT "target linking terms:\n";
    print OUT join("\n", keys %targetLinks, );

    close OUT;

#Done
    print "DONE!\n\n";
}

#NOTE, this is experimental code for using the implicit matrix as input
# to association measures and then rank. This provides a nice method of 
# association for implicit terms, but there are implementation problems
# primarily memory constraints or time constraints now, because this
# requires the entire implicit matrix be computed. This can be done, but
# access to it is then slow. Would require a major redo of the code
#
=comment
# performs LBD, but using implicit matrix ranking schemes.
# Since the order of operations for those methods are slighly different
# a new method has been created.
# input:  none
# output: none, but a results file is written to disk
sub performLBD_implicitMatrixRanking {
    my $self = shift;
    my $start; #used to record run times
    print  $self->_parametersToString();
    print "In Implicit Ranking\n";
    
#Get inputs
    my $startCuisRef = $self->_getStartCuis();
    my $linkingAcceptTypesRef = $self->_getAcceptTypes('linking');
    my $targetAcceptTypesRef = $self->_getAcceptTypes('target');
    print "startCuis = ".(join(',', @{$startCuisRef}))."\n";
    print "linkingAcceptTypes = ".(join(',', keys %{$linkingAcceptTypesRef}))."\n";
    print "targetAcceptTypes = ".(join(',', keys %{$targetAcceptTypesRef}))."\n";

#Score Implicit Connections
    $start = time();	
    my $scoresRef;
    $scoresRef = Rank::scoreImplicit_fromImplicitMatrix($startCuisRef,  $lbdOptions{'implicitInputFile'}, $lbdOptions{rankingMeasue}, $umls_association);
    print "Scored in: ".(time()-$start)."\n";
  
#Rank Implicit Connections
    $start = time();
    my $ranksRef = Rank::rankDescending($scoresRef);
    print "Ranked in: ".(time()-$start)."\n";

#Output The Results
    open OUT, ">$lbdOptions{implicitOutputFile}" 
	or die "unable to open implicit ouput file: "
	."$lbdOptions{implicitOutputFile}\n";
    my $outputString = $self->_rankedTermsToString($scoresRef, $ranksRef);
    my $paramsString = $self->_parametersToString();
    print OUT $paramsString;
    print OUT $outputString;
    close OUT;

#Done
    print "DONE!\n\n";
}
=cut


##################################################
################ Time Slicing ####################
##################################################

#NOTE: This function isn't really tested, and is really slow right now
# Generates precision and recall values by varying the threshold
# of the A->B ranking measure.
# input:  none
# output: none, but precision and recall values are printed to STDOUT
sub timeSlicing_generatePrecisionAndRecall_explicit {
    my $NUM_SAMPLES = 100; #TODO, read fomr file number of samples to average over for timeslicing
    my $self = shift;
    print "In timeSlicing_generatePrecisionAndRecall\n";

    my $numIntervals = 10;

#Get inputs
    my $startAcceptTypesRef = $self->_getAcceptTypes('start');
    my $linkingAcceptTypesRef = $self->_getAcceptTypes('linking');
    my $targetAcceptTypesRef = $self->_getAcceptTypes('target');


#Get the Explicit Matrix
    my $explicitMatrixRef;
    if(!defined $lbdOptions{'explicitInputFile'}) {
	die ("ERROR: explicitInputFile must be defined in LBD config file\n");
    }
    $explicitMatrixRef = Discovery::fileToSparseMatrix($lbdOptions{'explicitInputFile'});

#------------------------------------------

    #create the starting matrix
    my $startingMatrixRef 
	= TimeSlicing::generateStartingMatrix($explicitMatrixRef, \%lbdOptions, $startAcceptTypesRef, $NUM_SAMPLES, $umls_interface);

    #get association scores for the starting matrix
    my $assocScoresRef = TimeSlicing::getAssociationScores(
	$startingMatrixRef, $lbdOptions{'rankingMeasure'}, $umls_association);
    my ($min, $max) = TimeSlicing::getMinMax($assocScoresRef);
    my $range = $max-$min;

    #load the post cutoff matrix for the necassary rows
    my $postCutoffMatrixRef 
	= TimeSlicing::loadPostCutOffMatrix($startingMatrixRef, $explicitMatrixRef, $lbdOptions{'postCutoffFileName'});

    #apply a semantic type filter to the post cutoff matrix
    if ((scalar keys %{$targetAcceptTypesRef}) > 0) {
	    Filters::semanticTypeFilter_columns(
		$postCutoffMatrixRef, $targetAcceptTypesRef, $umls_interface);
    }

    #apply a threshold at $numIntervals% intervals to generate an 11 point
    # interpolated precision/recall curve for linking term ranking/thresholding
    #stats for collecting info about predicted vs. true
    my $predictedAverage = 0;
    my $trueAverage = 0; 
    my $trueMin = 99999;
    my $trueMax = -999999; 
    my $predictedMin = 999999;
    my $predictedMax = 999999;
    my $predictedTotal = 0;
    my $trueTotal = 0;
    my $allPairsCount = scalar keys %{$assocScoresRef};
    for (my $i = $numIntervals; $i >= 0; $i--) {

	#determine the number of samples to threshold
	my $numSamples = $i*($allPairsCount/$numIntervals);
	print "i, numSamples/allPairsCount = $i, $numSamples/$allPairsCount\n";
	#grab samples at just 10 to estimate the final point (this is what 
	# makes it an 11 point curve)
	if ($numSamples == 0) {
	    $numSamples = 10;
	}

	#apply a threshold (number of samples)
	my $thresholdedStartingMatrixRef = TimeSlicing::grabKHighestRankedSamples($numSamples, $assocScoresRef, $startingMatrixRef);

	#generate implicit knowledge
	my $implicitMatrixRef = Discovery::findImplicit($explicitMatrixRef, $thresholdedStartingMatrixRef);

	#Remove Known Connections
	$implicitMatrixRef 
	    = Discovery::removeExplicit($startingMatrixRef, $implicitMatrixRef);

	#apply a semantic type filter to the implicit matrix
	if ((scalar keys %{$targetAcceptTypesRef}) > 0) {
	    Filters::semanticTypeFilter_columns(
		$implicitMatrixRef, $targetAcceptTypesRef, $umls_interface);
	}

	#calculate precision and recall
	my ($precision, $recall) = TimeSlicing::calculatePrecisionRecall(
	    $implicitMatrixRef, $postCutoffMatrixRef);
	print "precision = $precision, recall = $recall\n";

	#calculate averages/min/max only for $i= $numIntervals, which is all terms
	if ($i == $numIntervals) {
	    #average over all terms
	    foreach my $rowKey(keys %{$implicitMatrixRef}) {
		#get the counts true and predicted for this term (row of matrix)
		my $numPredicted = scalar keys %{${$implicitMatrixRef}{$rowKey}};
		my $numTrue = scalar keys %{${$postCutoffMatrixRef}{$rowKey}};

		#sum counts
		$predictedAverage += $numPredicted;
		$trueAverage += $numTrue;
		
		#update min and max
		if ($numPredicted < $predictedMin) {
		    $predictedMin = $numPredicted;
		}
		if ($numPredicted > $predictedMax) {
		    $predictedMax = $numPredicted;
		}
		if ($numTrue < $trueMin) {
		    $predictedMin = $numTrue;
		}
		if ($numTrue > $trueMax) {
		    $predictedMax = $numTrue;
		}

		$predictedTotal += $numPredicted;
		$trueTotal += $numTrue;
	    }
	    #take the average, both true and predicted matrices
	    # have the same number of rows.
	    $predictedAverage /= (scalar keys %{$implicitMatrixRef});
	    $trueAverage /= (scalar keys %{$implicitMatrixRef});
	}
    } 

    #output stats
    print "predicted - total, min, max, average = $predictedTotal, $predictedMin, $predictedMax, $predictedAverage\n";
    print "true - total, min, max, average = $trueTotal, $trueMin, $trueMax, $trueAverage\n";
}


# generates precision and recall values by varying the threshold
# of the A->C ranking measure. Also generates precision at k, and
# mean average precision
# input:  none
# output: none, but precision, recall, precision at k, and map values
#         output to STDOUT
sub timeSlicing_generatePrecisionAndRecall_implicit {
    my $NUM_SAMPLES = 200; #TODO, read fomr file number of samples to average over for timeslicing
    my $self = shift;
    my $start; #used to record run times
    print "In timeSlicing_generatePrecisionAndRecall_implicit\n";

    #Get inputs
    my $startAcceptTypesRef = $self->_getAcceptTypes('start');
    my $linkingAcceptTypesRef = $self->_getAcceptTypes('linking');
    my $targetAcceptTypesRef = $self->_getAcceptTypes('target');

#-----------
# Starting Matrix Creation
#-----------
    #Get the Explicit Matrix
    print "loading explicit\n";
    my $explicitMatrixRef;
    if(!defined $lbdOptions{'explicitInputFile'}) {
	die ("ERROR: explicitInputFile must be defined in LBD config file\n");
    }
    $explicitMatrixRef = Discovery::fileToSparseMatrix($lbdOptions{'explicitInputFile'});

    #create the starting matrix
    print "generating starting\n";
    my $startingMatrixRef 
	= TimeSlicing::generateStartingMatrix($explicitMatrixRef, \%lbdOptions, $startAcceptTypesRef, $NUM_SAMPLES, $umls_interface);
#----------
    

#--------
# Gold Loading/Creation
#--------
    #load or create the gold matrix
    my $goldMatrixRef;
    if (exists $lbdOptions{'goldInputFile'}) {
	print "inputting gold\n";
	$goldMatrixRef = Discovery::fileToSparseMatrix($lbdOptions{'goldInputFile'});
    }
    else {
	print "loading post cutoff\n";
	$goldMatrixRef = TimeSlicing::loadPostCutOffMatrix($startingMatrixRef, $explicitMatrixRef, $lbdOptions{'postCutoffFileName'});

	#remove explicit knowledge from the post cutoff matrix
	$goldMatrixRef = Discovery::removeExplicit($startingMatrixRef, $goldMatrixRef);

	#apply a semantic type filter to the post cutoff matrix
	print "applying semantic filter to post-cutoff matrix\n";
	if ((scalar keys %{$targetAcceptTypesRef}) > 0) {
	    Filters::semanticTypeFilter_columns(
		$goldMatrixRef, $targetAcceptTypesRef, $umls_interface);
	}

	#TODO why is the gold matrix outputting with an extra line between samples?
	#output the gold matrix
	if (exists $lbdOptions{'goldOutputFile'}) {
	    print "outputting gold\n";
	    Discovery::outputMatrixToFile($lbdOptions{'goldOutputFile'}, $goldMatrixRef); 
	}
    }
#-------
  
#-------
# AB Scoring (if needed)
#-------
    #if using average minimum weight, grab the a->b scores, #TODO this is sloppy here, but it has to be here...how to make it fit better?
    my %abPairsWithScores = ();
    if ($lbdOptions{'rankingProcedure'} eq 'averageMinimumWeight'
		|| $lbdOptions{'rankingProcedure'} eq 'ltc_amw') {
	print "getting AB scores\n";

	#apply semantic type filter to columns only
	if ((scalar keys %{$linkingAcceptTypesRef}) > 0) {
	    Filters::semanticTypeFilter_columns(
		$explicitMatrixRef, $linkingAcceptTypesRef, $umls_interface);
	}
	#intitialize the abPairs to the frequency of co-ocurrence
	foreach my $row (keys %{$startingMatrixRef}) {
	    foreach my $col (keys %{${$startingMatrixRef}{$row}}) {
		$abPairsWithScores{"$row,$col"} = ${${$startingMatrixRef}{$row}}{$col}; 
	    }
	}
	Rank::getBatchAssociationScores(
	    \%abPairsWithScores, $explicitMatrixRef, $lbdOptions{'rankingMeasure'}, $umls_association);
    }
#--------

#------------
# Matrix Filtering/Thresholding
#------------
    #load or threshold the matrix
    if (exists $lbdOptions{'thresholdedMatrix'}) {
	print "loading thresholded matrix\n";
	$explicitMatrixRef = (); #clear (for memory)
	$explicitMatrixRef = Discovery::fileToSparseMatrix($lbdOptions{'thresholdedMatrix'});
    }
    #else {#TODO apply a threshold}
    #NOTE, we must threshold the entire matrix because that is how we are calculating association scores

    #Apply Semantic Type Filter to the explicit matrix
    print "applying semantic filter to explicit matrix\n";
    if ((scalar keys %{$linkingAcceptTypesRef}) > 0) {
	Filters::semanticTypeFilter_rowsAndColumns(
	    $explicitMatrixRef, $linkingAcceptTypesRef, $umls_interface);
    }

#------------
# Prediction Generation
#------------
    #load or create the predictions matrix
    my $predictionsMatrixRef;
    if (exists $lbdOptions{'predictionsInFile'}) {
	print "loading predictions\n";
	$predictionsMatrixRef = Discovery::fileToSparseMatrix($lbdOptions{'predictionsInFile'});
    }
    else {
	print "generating predictions\n";

	#generate implicit knowledge
	print "Squaring Matrix\n";
	$predictionsMatrixRef = Discovery::findImplicit(
	    $explicitMatrixRef, $startingMatrixRef);

	#Remove Known Connections
	print "Removing Known from Predictions\n";
	$predictionsMatrixRef 
	    = Discovery::removeExplicit($startingMatrixRef, $predictionsMatrixRef);

	#apply a semantic type filter to the predictions matrix
	print "Applying Semantic Filter to Predictions\n";
	if ((scalar keys %{$targetAcceptTypesRef}) > 0) {
	    Filters::semanticTypeFilter_columns(
		$predictionsMatrixRef, $targetAcceptTypesRef, $umls_interface);
	}

	#save the implicit knowledge matrix to file
	if (exists ($lbdOptions{'predictionsOutFile'})) {
	    print "outputting predictions\n";
	    Discovery::outputMatrixToFile($lbdOptions{'predictionsOutFile'}, $predictionsMatrixRef);
	}
    }

#-------------------------------------------

    #At this point, the explicitMatrixRef has been filtered and thresholded
    #The predictions matrix Ref has been generated from the filtered and 
    #  thresholded explicitMatrixRef, only rows of starting terms remain, filtered, and 
    #  had explicit removed
    #Association scores are generated using the explicitMatrixRef


#--------------
# Get the ranks of all predictions
#--------------
    #get the scores and ranks seperately for each row
    # thereby generating scores and ranks for each starting
    # term individually
    my %rowRanks = ();
    my ($n1pRef, $np1Ref, $npp);
    print "getting row ranks\n";
    foreach my $rowKey (keys %{$predictionsMatrixRef}) { 
	#grab rows from start and implicit matrices
	my %startingRow = ();
	$startingRow{$rowKey} = ${$startingMatrixRef}{$rowKey};
	my %implicitRow = ();
	$implicitRow{$rowKey} = ${$predictionsMatrixRef}{$rowKey};

	#Score Implicit Connections	
	my $scoresRef;
	if ($lbdOptions{'rankingProcedure'} eq 'allPairs') {
	    #get stats just a single time
	    if (!defined $n1pRef || !defined $np1Ref || !defined $npp) {
		($n1pRef, $np1Ref, $npp) = Rank::getAllStats($explicitMatrixRef);
	    }
	    $scoresRef = Rank::scoreImplicit_fromAllPairs(\%startingRow, $explicitMatrixRef, \%implicitRow, $lbdOptions{'rankingMeasure'}, $umls_association, $n1pRef, $np1Ref, $npp);
	} elsif ($lbdOptions{'rankingProcedure'} eq 'averageMinimumWeight') {
	    #get stats just a single time
	    if (!defined $n1pRef || !defined $np1Ref || !defined $npp) {
		($n1pRef, $np1Ref, $npp) = Rank::getAllStats($explicitMatrixRef);
	    }
	    $scoresRef = Rank::scoreImplicit_averageMinimumWeight(\%startingRow, $explicitMatrixRef, \%implicitRow, $lbdOptions{'rankingMeasure'}, $umls_association, \%abPairsWithScores, $n1pRef, $np1Ref, $npp);
	} elsif ($lbdOptions{'rankingProcedure'} eq 'linkingTermCount') {
	    $scoresRef = Rank::scoreImplicit_linkingTermCount(\%startingRow, $explicitMatrixRef, \%implicitRow);
	} elsif ($lbdOptions{'rankingProcedure'} eq 'frequency') {
	    $scoresRef = Rank::scoreImplicit_frequency(\%startingRow, $explicitMatrixRef, \%implicitRow);
	} elsif ($lbdOptions{'rankingProcedure'} eq 'ltcAssociation') {
	    $scoresRef = Rank::scoreImplicit_ltcAssociation(\%startingRow, $explicitMatrixRef, \%implicitRow, $lbdOptions{'rankingMeasure'}, $umls_association);
	} elsif ($lbdOptions{'rankingProcedure'} eq 'ltc_amw') {
	    #get stats just a single time
	    if (!defined $n1pRef || !defined $np1Ref || !defined $npp) {
		($n1pRef, $np1Ref, $npp) = Rank::getAllStats($explicitMatrixRef);
	    }
	    $scoresRef = Rank::scoreImplicit_LTC_AMW(\%startingRow, $explicitMatrixRef, \%implicitRow, $lbdOptions{'rankingMeasure'}, $umls_association, \%abPairsWithScores, $n1pRef, $np1Ref, $npp);
	}  else {
	    die ("Error: Invalid Ranking Procedure\n");
	}    
	
	#Rank Implicit Connections
	my $ranksRef = Rank::rankDescending($scoresRef);

	#save the row ranks
	$rowRanks{$rowKey} = $ranksRef;
    }

    #output the results at 10 intervals
    TimeSlicing::outputTimeSlicingResults($goldMatrixRef, \%rowRanks, 10);
}



##############################################################################
#        functions to grab parameters and inialize all input
##############################################################################
# method to create a new LiteratureBasedDiscovery object
# input: $optionsHashRef <- a reference to an LBD options hash
# output: a new LBD object
sub new {
    my $self = {};
    my $className = shift;
    my $optionsHashRef = shift;
    bless($self, $className);

    $self->_initialize($optionsHashRef);
    return $self;
}

# Initializes everything needed for Literature Based Discovery
# input: $optionsHashRef <- reference to LBD options hash (command line input)
# output: none, but global parameters are set
sub _initialize {
    my $self = shift;
    my $optionsHashRef = shift; 

    #initialize UMLS::Interface
    my %tHash = ();
    $tHash{'t'} = 1; #default hash values are with t=1 (silence module output)
    my $componentOptions = \%tHash;
    if (${$optionsHashRef}{'interfaceConfig'} ne '') {
	#read configuration file if its defined
	$componentOptions = 
	    $self->_readConfigFile(${$optionsHashRef}{'interfaceConfig'});
    }
    #else use default configuration
    $umls_interface = UMLS::Interface->new($componentOptions) 
	or die "Error: Unable to create UMLS::Interface object.\n";

    #initialize UMLS::Association
    $componentOptions = \%tHash;
    if (${$optionsHashRef}{'assocConfig'} ne '') {
	#read configuration file if its defined
	$componentOptions = 
	    $self->_readConfigFile(${$optionsHashRef}{'assocConfig'});
    }
    #else use default configuation
    $umls_association = UMLS::Association->new($componentOptions) or 
	die "Error: Unable to create UMLS::Association object.\n";

    #initialize LBD parameters
    %lbdOptions = %{$self->_readConfigFile(${$optionsHashRef}{'lbdConfig'})};
    
}    

# Reads the config file in as an options hash
# input: the name of a configuration file that has key fields in '<>'s, 
#        The '>' is followed directly by the value for that key, no space.
#        Each line of the file contains a new key-value pair (e.g. <key>value)
#        If no value is provided, a default value of 1 is set
# output: a hash ref to a hash containing each key value pair
sub _readConfigFile {
    my $self = shift;
    my $configFileName = shift;
    
    #read in all options from the config file
    open IN, $configFileName or die("Error: Cannot open config file: $configFileName\n");
    my %optionsHash = ();
    my $firstChar;
    while (my $line = <IN>) {
	#check if its a comment or blank line
	$firstChar = substr $line, 0, 1;
	
	if ($firstChar ne '#' && $line =~ /[^\s]+/) {
	    #line contains data, grab the key and value
	    $line =~ /<([^>]+)>([^\n]*)/;	  

	    #make sure the data was read in correctly
	    if (!$1) {
		print STDERR 
		    "Warning: Invalid line in $configFileName: $line\n";
	    }
	    else {
		#data was grabbed from the line, add to hash
		if ($2) {
		    #add key and value to the optionsHash
		    $optionsHash{$1} = $2;
		}
		else {
		    #add key and set default value to the optionsHash
		    $optionsHash{$1} = 1;
		}
	    }
	}
    }
    close IN;

    return \%optionsHash;
}

# transforms the string of start cuis to an array
# input:  none
# output: an array ref of CUIs
sub _getStartCuis {
    my $self = shift;
    my @startCuis = split(',',$lbdOptions{'startCuis'});
    return \@startCuis;
}

# transforms the string of target cuis to an array
# input:  none
# output: an array ref of CUIs
sub _getTargetCuis {
    my $self = shift;
    my @targetCuis = split(',',$lbdOptions{'targetCuis'});
    return \@targetCuis;
}

# transforms the string of accept types or groups into a hash of accept TUIs
# input:  a string specifying whether linking or target types are being defined
# output: a hash of acceptable TUIs
sub _getAcceptTypes {
    my $self = shift;
    my $stepString = shift; #either 'linking' or 'target'

    #get the accept types 
    my %acceptTypes = ();

    #add all types for groups specified
    my $string = $stepString.'AcceptGroups';
    if (defined $lbdOptions{$string}) {
	#accept groups were specified
	my @acceptGroups = split(',',$lbdOptions{$string});

	#add all the types of each group
	foreach my $group(@acceptGroups) {
	    my $typesRef = Filters::getTypesOfGroup($group, $umls_interface);
	    foreach my $key(keys %{$typesRef}) {
		$acceptTypes{$key} = 1;
	    }
	}
    }

    #add all types specified
    $string = $stepString.'AcceptTypes';
    if (defined $lbdOptions{$string}) {
	#convert each type to a tui and add
	my $tui;
	my @acceptTypes = split(',',$lbdOptions{$string});
	foreach my $abr(@acceptTypes) {
	    $tui = uc $umls_interface->getStTui($abr);
	    $acceptTypes{$tui} = 1;
	}
    }
    
    return \%acceptTypes;
}



##############################################################################
#        function to produce output
##############################################################################
# outputs the implicit terms to string
# input:  $scoresRef <- a reference to a hash of scores (hash{CUI}=score)
#         $ranksRef <- a reference to an array of CUIs ranked by their score
#         $printTo <- optional, outputs the $printTo top ranked terms. If not
#                     specified, all terms are output
# output: a line seperated string containing ranked terms, scores, and thier
#         preferred terms
sub _rankedTermsToString {
    my $self = shift;
    my $scoresRef = shift;
    my $ranksRef = shift;
    my $printTo = shift;

    #set printTo
    if (!$printTo) {
	$printTo = scalar @{$ranksRef};
    }
    
    #construct the output string
    my $string = '';
    my $index;
    for (my $i = 0; $i < $printTo; $i++) {
	#add the rank
	$index = $i+1;
	$string .= "$index\t";
	#add the score
	$string .= sprintf "%.5f\t", "${$scoresRef}{${$ranksRef}[$i]}\t";
	#add the CUI
	$string .= "${$ranksRef}[$i]\t";
	#add the name
	my $name = $umls_interface->getPreferredTerm(${$ranksRef}[$i]);
	#if no preferred name, get anything
	if (!defined $name || $name eq '') {
	    my $termListRef = $umls_interface->getTermList('C0440102');
	    if (scalar @{$termListRef} > 0) {
		$name = '.**'.${$termListRef}[0];
	    }
	}

	$string .= "$name\n";
    }

    #return the string of ranked terms
    return $string;
}

# converts the current objects parameters to a string
# input : none
# output: a string of parameters that were used for LBD
sub _parametersToString {
    my $self = shift;
        
    #LBD options
    my $paramsString = "Parameters:\n";
    foreach my $key (sort keys %lbdOptions) {
	$paramsString .= "$key -> $lbdOptions{$key}\n";
    }
    $paramsString .= "\n";
    return $paramsString;
    #association options? TODO
    #interface options? TODO
}


# returns the version currently being used
# input : none
# output: the version number being used
sub version {
    my $self = shift;
    return $VERSION;
}

##############################################################################
#        functions for debugging
##############################################################################
=comment
sub debugLBD {
    my $self = shift;
    my $startingCuisRef = shift;

    print "Starting CUIs = ".(join(',', @{$startingCuisRef}))."\n";

#Get the Explicit Matrix
    my ($explicitMatrixRef, $cuiToIndexRef, $indexToCuiRef, $matrixSize) = 
	Discovery::tableToSparseMatrix('N_11', $cuiFinder);
    print "Explicit Matrix:\n";
    _printMatrix($explicitMatrixRef, $matrixSize, $indexToCuiRef);
    print "-----------------------\n";

#Get the Starting Matrix
    my $startingMatrixRef = 
	Discovery::getRows($startingCuisRef, $explicitMatrixRef);
    print "Starting Matrix:\n";
    _printMatrix($startingMatrixRef, $matrixSize, $indexToCuiRef);
    print "-----------------------\n";
    
#Get Implicit Connections
    my $implicitMatrixRef 
	= Discovery::findImplicit($explicitMatrixRef, $startingMatrixRef, 
				  $indexToCuiRef, $matrixSize);
    print "Implicit Matrix:\n";
    _printMatrix($implicitMatrixRef, $matrixSize, $indexToCuiRef);
    print "-----------------------\n";

#Remove Known Connections
    $implicitMatrixRef = Discovery::removeExplicit($explicitMatrixRef, 
						   $implicitMatrixRef);
    print "Implicit Matrix with Explicit Removed\n";
    _printMatrix($implicitMatrixRef, $matrixSize, $indexToCuiRef);
    print "-----------------------\n";
    print "\n\n";

#Test N11, N1P, etc...
    #NOTE...always do n11 first, if n11 = -1, no need to compute the others...there is no co-occurrence between them
    my $n11 = Rank::getN11('C0','C2',$explicitMatrixRef);
    my $npp = Rank::getNPP($explicitMatrixRef);
    my $n1p = Rank::getN1P('C0', $explicitMatrixRef);
    my $np1 = Rank::getNP1('C2', $explicitMatrixRef); 
    print "Contingency Table Values from Explicit Matrix\n";
    print "n11 = $n11\n";
    print "npp = $npp\n";
    print "n1p = $n1p\n";
    print "np1 = $np1\n";

#Test other rank methods
    my $scoresRef = Rank::scoreImplicit_fromAllPairs($startingMatrixRef, $explicitMatrixRef, $implicitMatrixRef, $lbdOptions{rankingMethod}, $umls_association);
    my $ranksRef = Rank::rankDescending($scoresRef);
    print "Scores: \n";
    foreach my $cui (keys %{$scoresRef}) {
	print "   scores{$cui} = ${$scoresRef}{$cui}\n";
    }
    print "Ranks = ".join(',', @{$ranksRef})."\n";
}

sub _printMatrix {
    my $matrixRef = shift;
    my $matrixSize = shift;
    my $indexToCuiRef = shift;
    
    for (my $i = 0; $i < $matrixSize; $i++) {
	my $index1 = ${$indexToCuiRef}{$i};
	for (my $j = 0; $j < $matrixSize; $j++) {
	    my $printed = 0;
	    my $index2 = ${$indexToCuiRef}{$j};
	    my $hash1Ref =  ${$matrixRef}{$index1};

	    if (defined $hash1Ref) {
		my $val = ${$hash1Ref}{$index2};
		if (defined $val) {
		    print $val."\t";
		    $printed = 1;
		}
	    }
	    if (!$printed) {
		print "0\t";
	    }
	}
	print "\n";
    }
}
=cut


1;
