package Algorithm::TrunkClassifier::DecisionTrunk;

use warnings;
use strict;

our $VERSION = 'v1.0.1';

#Description: DecisionTrunk constructor
#Parameters: (1) TrunkClassifier::DecisionTrunk class
#Return value: TrunkClassifier::DecisionTrunk object
sub new($){
	my $class = shift();
	my @names;
	my @lower;
	my @higher;
	my @lowerClass;
	my @higherClass;
	my $self = {
		"level_name" => \@names,
		"lower_threshold" => \@lower,
		"higher_threshold" => \@higher,
		"lower_class" => \@lowerClass,
		"higher_class" => \@higherClass
	};
	bless($self, $class);
	return $self;
}

#Description: Adds a decision level to the trunk
#Parameters: (1) TrunkClassifier::DecisionTrunk object, (2) level name, (3) lower threshold, (4) higher threshold, (5) lower class, (6) higher class
#Return value: None
sub addLevel($ $ $ $ $ $){
	my ($self, $levelName, $lowerT, $higherT, $lowerC, $higherC) = @_;
	push(@{$self->{"level_name"}}, $levelName);
	push(@{$self->{"lower_threshold"}}, $lowerT);
	push(@{$self->{"higher_threshold"}}, $higherT);
	push(@{$self->{"lower_class"}}, $lowerC);
	push(@{$self->{"higher_class"}}, $higherC);
}

#Description: Classifies the test set based on the thresholds in the trunk
#Parameters: (1) TrunkClassifier::DecisionTrunk object, (2) TrunkClassifier::DataWrapper object, (3) class one name, (4) class two name
#			 (5) class report array reference, (6) verbose flag
#Return value: Ratio of correct to total classification performance
sub classify($ $ $ $ $ $){
	my ($self, $testSet, $ClassOne, $classTwo, $classReport, $VERBOSE) = @_;
	my $class;
	my @classification;
	my $ratioCorrect = 0;
	for(my $sampleIndex = 0; $sampleIndex < $testSet->getNumSamples(); $sampleIndex++){
		$class = "";
		for(my $levelIndex = 0; $levelIndex < scalar(@{$self->{"level_name"}}); $levelIndex++){
			my $probeIndex = $testSet->getProbeIndex($self->{"level_name"}[$levelIndex]);
			my @probeRow = $testSet->getMatrixRow($probeIndex);
			if($probeRow[$sampleIndex] <= $self->{"lower_threshold"}[$levelIndex]){
				$class = $self->{"lower_class"}[$levelIndex];
				my $lvl = $levelIndex + 1;
				my $sampleName = $testSet->getSampleName($sampleIndex);
				push(@{$classReport}, "$sampleName in $lvl-$class");
				last;
			}
			elsif($probeRow[$sampleIndex] >= $self->{"higher_threshold"}[$levelIndex]){
				$class = $self->{"higher_class"}[$levelIndex];
				my $lvl = $levelIndex + 1;
				my $sampleName = $testSet->getSampleName($sampleIndex);
				push(@{$classReport}, "$sampleName in $lvl-$class");
				last;
			}
		}
		push(@classification, $class);
	}
	my @classVector = @{$testSet->getClassVector()};
	for(my $sampleIndex = 0; $sampleIndex < $testSet->getNumSamples(); $sampleIndex++){
		if($classification[$sampleIndex] eq $classVector[$sampleIndex]){
			$ratioCorrect++;
		}
	}
	$ratioCorrect /= $testSet->getNumSamples();
	return $ratioCorrect;
}

#Description: Returns a text report of the trunk structure
#Parameters: (1) TrunkClassifier::DecisionTrunk object
#Return value: String containing the trunk structure
sub report($){
	my $self = shift();
	my $report = "";
	for(my $level = 0; $level < scalar(@{$self->{"level_name"}}); $level++){
		my $name = $self->{"level_name"}[$level];
		my $lowerT = $self->{"lower_threshold"}[$level];
		my $lowerC = $self->{"lower_class"}[$level];
		my $higherT = $self->{"higher_threshold"}[$level];
		my $higherC = $self->{"higher_class"}[$level];
		$report .= "\t$name\n<= $lowerT ($lowerC)\t\t> $higherT ($higherC)\n\n";
	}
	$report .= "--------------------------------------------------\n\n";
	return $report;
}

return 1;
