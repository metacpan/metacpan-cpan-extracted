package Algorithm::TrunkClassifier::Classification;

use warnings;
use strict;

use Algorithm::TrunkClassifier::DataWrapper;
use Algorithm::TrunkClassifier::FeatureSelection;
use Algorithm::TrunkClassifier::DecisionTrunk;
use Algorithm::TrunkClassifier::Util;
use POSIX;

our $VERSION = "v1.0.1";

#Description: Function responsible for building decision trunks and classifying test samples using LOOCV
#Parameters: (1) Package, (2) input dataset, (3) test dataset, (4) classification procedure, (5) split percent,
#            (6) testset data file name, (7) classification variable name, (8) output folder name,
#            (9) number of levels, (10) verbose flag, (11) input data file name (12) useall flag
#Return value: None
sub trainAndClassify($ $ $ $ $ $ $ $ $ $ $ $ $){
	shift(@_);
	my ($dataWrapper, $testset, $CLASSIFY, $SPLITPERCENT, $TESTFILE, $CLASSNAME, $OUTPUT, $LEVELS, $VERBOSE, $DATAFILE, $USEALL) = @_;
	
	#Create output files
	if(!-e $OUTPUT && $OUTPUT ne "."){
		system("mkdir $OUTPUT");
	}
	open(PERFORMANCE, ">$OUTPUT/performance.txt") or die "Error: Unable to create output file\n";
	open(LOO_TRUNKS, ">$OUTPUT/loo_trunks.txt") or die "Error: Unable to create output file\n";
	open(CTS_TRUNKS, ">$OUTPUT/cts_trunks.txt") or die "Error: Unable to create output file\n";
	open(REPORT, ">$OUTPUT/class_report.txt") or die "Error: Unable to create output file\n";
	open(LOG, ">$OUTPUT/log.txt") or die "Error: Unable to create output file\n";
	
	#Establish training and test set
	my $trainingSet;
	my $testSet;
	if($CLASSIFY eq "loocv"){
		$trainingSet = $dataWrapper->copy();
	}
	elsif($CLASSIFY eq "split"){
		my $containsBoth = 0;
		while(!$containsBoth){
			$trainingSet = $dataWrapper->copy();
			$testSet = $trainingSet->splitSamples($SPLITPERCENT);
			my $class1 = $trainingSet->getClassOneName();
			my $class2 = $trainingSet->getClassTwoName();
			if($trainingSet->getClassSize($class1) && $trainingSet->getClassSize($class2)){
				$containsBoth = 1;
			}
		}
	}
	elsif($CLASSIFY eq "dual"){
		$trainingSet = $dataWrapper->copy();
		$testSet = $testset->copy();
	}
	
	#Build trunks using leave-one-out
	my %featureOccurrence;
	my %selectedFeatures;
	my %looTrunks = ("1" => [], "2" => [], "3" => [], "4" => [], "5" => []);
	my $levelBreak = 0;
	for(my $levelLimit = 1; $levelLimit <= 5; $levelLimit++){
		if($VERBOSE){
			print("Trunk classifier: Building decision trunks with $levelLimit level(s) using leave-one-out\n");
		}
		
		#Build one trunk for each left out sample
		for(my $sampleIndex = 0; $sampleIndex < $trainingSet->getNumSamples(); $sampleIndex++){
			if($VERBOSE){
				print("Trunk classifier: Fold ", $sampleIndex + 1, " of ", $dataWrapper->getNumSamples(), "\n");
			}
			my $buildSet = $trainingSet->copy();
			$buildSet->leaveOneOut($sampleIndex);
			my $decisionTrunk = buildTrunk($buildSet, $levelLimit, $sampleIndex, \%featureOccurrence, \%selectedFeatures, \$levelBreak, $VERBOSE);
			
			#Add trunk to hash
			push(@{$looTrunks{$levelLimit}}, $decisionTrunk);
			
		}
		
		if($levelBreak){
			undef $featureOccurrence{$levelLimit};
			$looTrunks{$levelLimit} = [];
			last;
		}
	}
	
	#Build trunks using complete training set
	my %ctsTrunks = ("1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0);
	my %selFeats;
	my %dummyHash;
	$levelBreak = 0;
	if($VERBOSE){
			print("Trunk classifier: Building decision trunks using complete training set\n");
		}
	for(my $levelLimit = 1; $levelLimit <= 5; $levelLimit++){
		my $buildSet = $trainingSet->copy();
		my $decisionTrunk = buildTrunk($buildSet, $levelLimit, 0, \%dummyHash, \%selFeats, \$levelBreak, $VERBOSE);
		
		#Add trunk to hash
		$ctsTrunks{$levelLimit} = $decisionTrunk;
		
		if($levelBreak){
			last;
		}
	}
	
	#Determine number of levels to use for classification
	my @numTrunkLevels;
	my $trunkType = "";
	if($CLASSIFY eq "loocv"){
		$trunkType = "LOO";
	}
	elsif($CLASSIFY eq "split" || $CLASSIFY eq "dual"){
		$trunkType = "CTS"
	}
	if(!$USEALL && $LEVELS){
		if(!@{$looTrunks{$LEVELS}}){
			for(my $levelIndex = $LEVELS - 1; $levelIndex > 0; $levelIndex--){
				if(@{$looTrunks{$LEVELS}}){
					push(@numTrunkLevels, $levelIndex);
					warn "Warning: Supplied level is to high, using $trunkType trunks with $levelIndex level(s) instead\n";
				}
			}
		}
		else{
			push(@numTrunkLevels, $LEVELS);
			if($VERBOSE){
				print("Trunk classifier: Using $trunkType trunks with $numTrunkLevels[0] level(s) (forced)\n");
			}
		}
	}
	elsif(!$USEALL){
		push(@numTrunkLevels, stabilityCheck(\%featureOccurrence, $dataWrapper->getNumSamples()));
		if($VERBOSE){
			print("Trunk classifier: Using $trunkType trunks with $numTrunkLevels[0] level(s) (stability)\n");
		}
	}
	else{
		push(@numTrunkLevels, (1, 2, 3, 4, 5));
		if($VERBOSE){
			print("Trunk classifier: Using all $trunkType trunks for classification\n");
		}
	}
	
	#Classify test set
	my @performance;
	my @classReport;
	my $avePerformance;
	my $procedure = "";
	if($CLASSIFY eq "loocv"){
		$procedure = "LOOCV on input dataset";
	}
	elsif($CLASSIFY eq "split"){
		$procedure = "split-sample testset";
	}
	elsif($CLASSIFY eq "dual"){
		$procedure = "supplied test dataset";
	}
	if($VERBOSE){
		print("Trunk classifier: Performing classification using $procedure\n");
	}
	foreach my $numLevels (@numTrunkLevels){
		$avePerformance = 0;
		my @perArray;
		if(!@{$looTrunks{$numLevels}}){
			last;
		}
		if($USEALL){
			if($numLevels > 1){
				push(@performance, "\n");
				push(@classReport, "\n");
			}
			push(@performance, "Performance for trunks with $numLevels levels\n");
			push(@classReport, "Classification using trunks with $numLevels levels\n");
		}
		
		#Leave-one-out cross validation
		if($CLASSIFY eq "loocv"){
			for(my $sampleIndex = 0; $sampleIndex < $trainingSet->getNumSamples(); $sampleIndex++){
				if($VERBOSE){
					print("Trunk classifier: Fold ", $sampleIndex + 1, " of ", $dataWrapper->getNumSamples(), "\n");
				}
				my $trainingBuffer = $trainingSet->copy();
				$testSet = $trainingBuffer->leaveOneOut($sampleIndex);
				
				#Classify test set
				my $perBuffer = ${$looTrunks{$numLevels}}[$sampleIndex]->classify($testSet, $testSet->getClassOneName(),
								$testSet->getClassTwoName(), \@classReport, $VERBOSE);
				$avePerformance += $perBuffer;
				my $indexBuffer = $sampleIndex + 1;
				$perBuffer *= 100;
				$perBuffer = "Fold $indexBuffer: $perBuffer %";
				push(@perArray, $perBuffer);
			}
			$avePerformance = ($avePerformance / $dataWrapper->getNumSamples()) * 100;
			unshift(@perArray, "Average: $avePerformance %");
			push(@performance, @perArray);
		}
		elsif($CLASSIFY eq "split" || $CLASSIFY eq "dual"){
			my $perBuffer = $ctsTrunks{$numLevels}->classify($testSet, $testSet->getClassOneName(),
							$testSet->getClassTwoName(), \@classReport, $VERBOSE);
			$perBuffer *= 100;
			$perBuffer = "Performance: $perBuffer %";
			push(@performance, $perBuffer);
		}
	}
	
	#Write results to output files
	if($VERBOSE){
		print("Trunk classifier: Writing output\n");
	}
	my $trunkCount;
	foreach my $numLevels (@numTrunkLevels){
		$trunkCount = 0;
		if(!@{$looTrunks{$numLevels}}){
			last;
		}
		print(LOO_TRUNKS ">Trunks with $numLevels level(s)\n\n");
		foreach my $trunk (@{$looTrunks{$numLevels}}){
			$trunkCount++;
			print(LOO_TRUNKS ">Trunk $trunkCount\n", $trunk->report());
		}
		print(CTS_TRUNKS ">Trunk with $numLevels level(s)\n\n");
		print(CTS_TRUNKS $ctsTrunks{$numLevels}->report());
	}
	if($USEALL){
		$numTrunkLevels[0] = "USEALL";
	}
	print(PERFORMANCE join("\n", @performance));
	print(REPORT join("\n", @classReport));
	if($CLASSIFY ne "dual"){
		$TESTFILE = "NA";
	}
	if($CLASSIFY ne "split"){
		$SPLITPERCENT = "NA";
	}
	my $name1 = $dataWrapper->getClassOneName();
	my $name2 = $dataWrapper->getClassTwoName();
	my $log = "Trunk classifier log\n";
	$log .= "Input data file: $DATAFILE\n";
	$log .= "Testset data file: $TESTFILE\n";
	$log .= "Procedure: $CLASSIFY\n";
	$log .= "Split percent: $SPLITPERCENT\n";
	$log .= "Number of levels: $numTrunkLevels[0]\n";
	$log .= "Classification variable: $CLASSNAME\n";
	$log .= "Training set classes:\n";
	if($CLASSIFY eq "loocv"){
		$log .= "\tClass one size: " . $dataWrapper->getClassSize($name1) . " ($name1)\n";
		$log .= "\tClass two size: " . $dataWrapper->getClassSize($name2) . " ($name2)\n";
	}
	else{
		$log .= "\tClass one size: " . $trainingSet->getClassSize($name1) . " ($name1)\n";
		$log .= "\tClass two size: " . $trainingSet->getClassSize($name2) . " ($name2)\n";
	}
	$log .= "Test set classes:\n";
	if($CLASSIFY eq "loocv"){
		$log .= "\tClass one size: NA\n";
		$log .= "\tClass two size: NA\n";
	}
	else{
		$log .= "\tClass one size: " . $testSet->getClassSize($name1) . " ($name1)\n";
		$log .= "\tClass two size: " . $testSet->getClassSize($name2) . " ($name2)\n";
	}
	$log .= "Version: $VERSION";
	print(LOG $log);
	close(PERFORMANCE);
	close(LOO_TRUNKS);
	close(CTS_TRUNKS);
	close(REPORT);
	close(LOG);
	if($VERBOSE){
		print("Trunk classifier: Job finished\n");
	}
}

#Description: Wrapper for the trunk build loop
#Parameters: (1) Training dataset, (2) level limit, (3) sample index, (4) feature occurrence hash ref,
#            (5) selected features hash ref, (6) level break flag ref, (7) verbose flag
#Return value: Decision trunk object
sub buildTrunk($ $ $ $ $ $ $){
	my ($buildSet, $levelLimit, $sampleIndex, $featOccurRef, $selFeatRef, $levelBreakRef, $VERBOSE) = @_;
	
	#Trunk build loop
	my $decisionTrunk = Algorithm::TrunkClassifier::DecisionTrunk->new();
	my $noSampleBreak = 0;
	for(my $levelIndex = 1; $levelIndex <= $levelLimit; $levelIndex++){
	
		#Perform feature selection
		my $featureName;
		my $featureIndex;
		my @expRow;
		if(!$selFeatRef->{$sampleIndex}{$levelIndex}){
			$featureIndex = Algorithm::TrunkClassifier::FeatureSelection::indTTest(
				$buildSet->getDataMatrix(), $buildSet->getNumProbes(),
				$buildSet->getNumSamples(), $buildSet->getClassVector(),
				$buildSet->getClassOneName(), $buildSet->getClassTwoName());
			$featureName = $buildSet->getProbeName($featureIndex);
			@expRow = $buildSet->getMatrixRow($featureIndex);
			my @savedRow = $buildSet->getMatrixRow($featureIndex);
			$buildSet->removeProbe($featureIndex);
			$selFeatRef->{$sampleIndex}{$levelIndex} = {"feature" => $featureName, "index" => $featureIndex, "row" => \@savedRow};
			if(!$featOccurRef->{$levelIndex}{$featureName}){
				$featOccurRef->{$levelIndex}{$featureName} = 1;
			}
			else{
				$featOccurRef->{$levelIndex}{$featureName}++;
			}
		}
		else{
			$featureName = $selFeatRef->{$sampleIndex}{$levelIndex}{"feature"};
			$featureIndex = $selFeatRef->{$sampleIndex}{$levelIndex}{"index"};
			@expRow = @{$selFeatRef->{$sampleIndex}{$levelIndex}{"row"}};
			$buildSet->removeProbe($featureIndex);
		}
		
		#Initialise variables
		my @expBuffer = @expRow;
		my @classSetInd = (0 .. ($buildSet->getNumSamples() - 1));
		my @classVector = @{$buildSet->getClassVector()};
		my $numSamples = $buildSet->getNumSamples();
		Algorithm::TrunkClassifier::Util::dataSort(\@expRow, \@classVector);
		Algorithm::TrunkClassifier::Util::dataSort(\@expBuffer, \@classSetInd);
		
		#Determine quartile thresholds
		my $quantStep = $numSamples / 4;
		my $lowerThresh;
		my $higherThresh;
		my $lowFloor = floor($quantStep);
		$lowerThresh = ($expRow[$lowFloor] + $expRow[$lowFloor+1]) / 2;
		my $highFloor = floor($quantStep * 3);
		if(!$expRow[$highFloor+1]){
			$higherThresh = $expRow[$highFloor];
		}
		else{
			$higherThresh = ($expRow[$highFloor] + $expRow[$highFloor+1]) / 2;
		}
		
		#Determine low and high class
		my $lowerClass = "";
		my $higherClass = "";
		if($classVector[0] eq $buildSet->getClassOneName()){
			$lowerClass = $buildSet->getClassOneName();
			$higherClass = $buildSet->getClassTwoName();
		}
		elsif($classVector[0] eq $buildSet->getClassTwoName()){
			$lowerClass = $buildSet->getClassTwoName();
			$higherClass = $buildSet->getClassOneName();
		}
		
		#Determine samples in quartiles
		my @indToRemove;
		my $decisionBuffer;
		my $lowerDecision;
		my $higherDecision;
		if($levelIndex < $levelLimit){
		
			#Lower quartile
			$decisionBuffer = "";
			for(my $classSample = 0; $classSample < $numSamples; $classSample++){
				if($classVector[$classSample] ne $lowerClass){
					if($expRow[$classSample] > $lowerThresh){
						$decisionBuffer = $lowerThresh;
					}
					else{
						$decisionBuffer = ($expRow[$classSample - 1] + $expRow[$classSample]) / 2;
					}
					last;
				}
				if($expRow[$classSample] <= $lowerThresh){
					push(@indToRemove, $classSetInd[$classSample]);
				}
				else{
					$decisionBuffer = $lowerThresh;
					last;
				}
			}
			$lowerDecision = $decisionBuffer;
			
			#Higher quartile
			$decisionBuffer = "";
			for(my $classSample = $numSamples - 1; $classSample >= 0; $classSample--){
				if($classVector[$classSample] ne $higherClass){
					if($expRow[$classSample] < $higherThresh){
						$decisionBuffer = $higherThresh;
					}
					elsif($classSample != $numSamples - 1){
						$decisionBuffer = ($expRow[$classSample] + $expRow[$classSample + 1]) / 2;
					}
					else{
						$decisionBuffer = $expRow[$classSample];
					}
					last;
				}
				if($expRow[$classSample] >= $higherThresh){
					push(@indToRemove, $classSetInd[$classSample]);
				}
				else{
					$decisionBuffer = $higherThresh;
					last;
				}
			}
			$higherDecision = $decisionBuffer;
		}
		else{
			#Do not use quartiles at last level of trunk
			$decisionBuffer = "";
			for(my $classSample = 0; $buildSet->getNumSamples(); $classSample++){
				if($classVector[$classSample] ne $lowerClass){
					$decisionBuffer = ($expRow[$classSample - 1] + $expRow[$classSample]) / 2;
					last;
				}
			}
			$lowerDecision = $decisionBuffer;
			for(my $classSample = $numSamples - 1; $classSample >= 0; $classSample--){
				if($classVector[$classSample] ne $higherClass){
					if($classSample != $numSamples - 1){
						$decisionBuffer = ($expRow[$classSample] + $expRow[$classSample + 1]) / 2;
					}
					else{
						$decisionBuffer = $expRow[$classSample];
					}
					last;
				}
			}
			$higherDecision = $decisionBuffer;
			$lowerDecision = ($lowerDecision + $higherDecision) / 2;
			$higherDecision = $lowerDecision;
		}
		
		#Remove samples in quartiles
		@indToRemove = sort {$b <=> $a} @indToRemove;
		foreach my $index (@indToRemove){
			$buildSet->removeSample($index);
		}
		
		#Check that there are at least one sample left in each class and at least four samples left in total
		my $classOneSize = $buildSet->getClassSize($buildSet->getClassOneName());
		my $classTwoSize = $buildSet->getClassSize($buildSet->getClassTwoName());
		if($levelIndex < $levelLimit && ($classOneSize < 1 || $classTwoSize < 1 || $classOneSize + $classTwoSize < 4)){
			if($VERBOSE){
				print("Trunk classifier: Not enough samples, stopping at level $levelIndex of $levelLimit\n");
			}
			$noSampleBreak = 1;
			${$levelBreakRef} = 1;
			$lowerDecision = ($lowerDecision + $higherDecision) / 2;
			$higherDecision = $lowerDecision;
		}
		
		#Add level to decision trunk
		$decisionTrunk->addLevel($featureName, $lowerDecision, $higherDecision, $lowerClass, $higherClass);
		
		if($noSampleBreak){
			last;
		}
	}
	return $decisionTrunk;
}

#Description: Determine the decision trunk level with highest feature selection stability
#Parameters: (1) Hash reference containing selected features, (2) number of samples in the dataset
#Return value: Number of decision trunk levels to use for classification
sub stabilityCheck($ $){
	my ($hashRef, $numSamples) = @_;
	my %featOccurrence = %{$hashRef};
	my $numThresh = 6;
	my $chosenLevel = 0;
	foreach my $levelIndex (1 .. 5){
		if(!$featOccurrence{$levelIndex}){
			next;
		}
		my %features = %{$featOccurrence{$levelIndex}};
		my $numFeats = scalar(keys(%features));
		if($numFeats > $numThresh){
			next;
		}
		$chosenLevel = $levelIndex;
	}
	if(!$chosenLevel){
		$chosenLevel = 1;
	}
	return $chosenLevel;
}

return 1;
