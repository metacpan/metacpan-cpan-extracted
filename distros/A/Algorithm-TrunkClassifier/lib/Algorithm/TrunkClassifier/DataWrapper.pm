package Algorithm::TrunkClassifier::DataWrapper;

use warnings;
use strict;

use POSIX;

our $VERSION = "v1.0.1";

my $NULL_CLASS = "#NA";
my $PROSPECT_SAMPLES = "samples";
my $PROSPECT_PROBES = "probes";
my $PROSPECT_CLASSES = "classes";

#Description: TrunkClassifier::DataWrapper constructor
#Parameters: (1) TrunkClassifier::DataWrapper, (2) classification variable name, (3) prospect flag,
#            (4) supplementary file name, (5) input data file name, (6) verbose flag, (7) dataset type
#Return value: TrunkClassifier::DataWrapper object
sub new{
	my ($class, $className, $prospect, $suppFileName, $dataFileName, $VERBOSE, $datasetType) = @_;
	my $self = {
		"colnames" => "",
		"rownames" => "",
		"data_matrix" => "",
		"class_vector" => "",
		"class_one" => "",
		"class_two" => ""
	};
	bless($self, $class);
	if(scalar(@_) == 1){
		return $self;
	}
	
	#If supplementary file is given, write new input data file with meta data
	if($suppFileName){
		$dataFileName = readSuppFile($suppFileName, $dataFileName, $VERBOSE, $datasetType);
	}
	
	#Read input data file
	readExpData($self, $className, $prospect, $dataFileName, $datasetType);
	return $self;
}

#Description: Reads the supplementary file and writes new input data file with meta data
#Parameters: (1) supplementary file name, (2) input data file name, (3) dataset type
#Return value: New input data file name
sub readSuppFile($ $ $ $){
	my ($suppFileName, $dataFileName, $VERBOSE, $datasetType) = @_;

	#Read supplementary file
	open(SUPP_FILE, $suppFileName) or die "Error: Unable to open supplementary file '$suppFileName'\n";
	my @suppFile = <SUPP_FILE>;
	my $content = join("", @suppFile);
	$content =~ s/\r|\n\r|\r\n/\n/g;
	@suppFile = split(/\n+/, $content);
	close(SUPP_FILE);
	
	#Extract classification variable names
	my @classNames = split(/\t/, shift(@suppFile));
	my $numCols = scalar(@classNames);
	shift(@classNames);
	if($numCols < 2){
		warn "Warning: No classification variable names found in supplementary file\n";
		return $dataFileName;
	}
	foreach my $className (@classNames){
		$className = uc($className);
	}
	my %classes;
	foreach my $classVar (@classNames){
		$classes{$classVar} = {};
	}
	
	#Determine classes of each classification variable and assign classes to samples
	my %sampleClasses;
	for(my $lineIndex = 0; $lineIndex < scalar(@suppFile); $lineIndex++){
		if($suppFile[$lineIndex] =~ /^\s*$/){
			next;
		}
		my @cols = split(/\t/, $suppFile[$lineIndex]);
		if(scalar(@cols) != $numCols){
			$lineIndex++;
			die "Error: Wrong number of columns in supplmentary file at line $lineIndex\n";
		}
		my $sampleName = uc(shift(@cols));
		$sampleName =~ s/\s+//g;
		if(!$sampleName){
			$lineIndex++;
			die "Error: Missing sample name in supplmentary file at line $lineIndex\n";
		}
		for(my $classVarIndex = 0; $classVarIndex < scalar(@classNames); $classVarIndex++){
			my $class = uc($cols[$classVarIndex]);
			$class =~ s/\s+//g;
			if(!$class){
				my $lineWarn = $classVarIndex + 1;
				warn "Warning: Missing class in supplmentary file at line $lineWarn, replacing with #NA\n";
				$class = $NULL_CLASS;
			}
			$sampleClasses{$sampleName}[$classVarIndex] = $class;
			if($class ne $NULL_CLASS && !$classes{$classNames[$classVarIndex]}{$class}){
				$classes{$classNames[$classVarIndex]}{$class} = 1;
			}
		}
	}
	foreach my $classVar (keys(%classes)){
		if(scalar(keys(%{$classes{$classVar}})) != 2){
			die "Error: Class variable $classVar in supplementary file does not have two classes\n";
		}
	}
	if(!%sampleClasses){
		warn "Warning: No sample classes found in supplementary file\n";
		return $dataFileName;
	}
	
	#Read input data file and write new data file with classification info
	open(DATA_FILE, $dataFileName) or die "Unable to open $datasetType '$dataFileName'\n";
	my @dataFile = <DATA_FILE>;
	close(DATA_FILE);
	my @header = split(/\t/, $dataFile[0]);
	shift(@header);
	chomp(@header);
	foreach my $sampleName (@header){
		$sampleName = uc($sampleName);
		$sampleName =~ s/\n|\r//g;
	}
	$dataFileName =~ s/\.[^.]+$/_wmeta.txt/;
	if($VERBOSE){
		print("Trunk classifier: Supplementary file supplied, writing new $datasetType with meta data\n");
	}
	open(DATA_FILE, ">$dataFileName") or die "Unable to create new data file '$dataFileName'\n";
	my $meta = "";
	for(my $classVarIndex = 0; $classVarIndex < scalar(@classNames); $classVarIndex++){
		my $className = $classNames[$classVarIndex];
		my @classKeys = keys(%{$classes{$className}});
		$meta .= "#CLASSVAR $className @classKeys\n";
		$meta .= "#CLASSMEM $className";
		foreach my $sampleName (@header){
			if(!$sampleClasses{$sampleName}[$classVarIndex]){
				warn "Warning: Sample '$sampleName' has no '$className' class in supplementary file\n";
				$meta .= " " . "#NA";
			}
			else{
				$meta .= " " . $sampleClasses{$sampleName}[$classVarIndex];
			}
		}
		$meta .= "\n";
	}
	print(DATA_FILE $meta . join("", @dataFile));
	close(DATA_FILE);
	return $dataFileName;
}

#Description: Reads input data file with expression values and meta data
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) classification variable name
#            (3) prospect flag, (4) input data file name, (5) dataset type
#Return value: None
sub readExpData($ $ $ $ $){
	my ($self, $className, $prospect, $dataFileName, $datasetType) = @_;
	$className = uc($className);
	
	#Read input data file
	if(!open(DATA_FILE, $dataFileName)){
		die "Error: Unable to open $datasetType '$dataFileName'\n";
	}
	my @dataFile = <DATA_FILE>;
	close(DATA_FILE);
	my $content = join("", @dataFile);
	$content =~ s/\r|\n\r|\r\n/\n/g;
	@dataFile = split(/\n+/, $content);

	foreach my $row (@dataFile){
		$row =~ s/\n//g;
	}
	
	#Extract meta data rows
	my @metarows;
	my $rowcounter = 0;
	while($rowcounter < scalar(@dataFile)){
		$dataFile[$rowcounter] =~ s/^\s+//;
		if($dataFile[$rowcounter] =~ /^\s*$/){
			shift(@dataFile);
		}
		elsif($dataFile[$rowcounter] =~ /^#/){
			push(@metarows, shift(@dataFile));
		}
		else{
			$rowcounter++;
		}
	}
	
	#Extract samples
	my @samples = split(/\t/, shift(@dataFile));
	shift(@samples);
	my $totNumSamples = scalar(@samples);
	if(!$totNumSamples){
		die "Error: No samples in $datasetType\n";
	}
	
	#Check that class variable exists and that all samples have valid class membership
	my %classes;
	my %membership;
	foreach my $row (@metarows){
		if($row =~ /^#CLASSVAR/){
			my @cols = split(/\s+/, $row);
			shift(@cols);
			if(!$cols[0]){
				warn "Warning: CLASSVAR name missing in meta data of $datasetType\n";
				next;
			}
			if(!$cols[1] || !$cols[2]){
				warn "Warning: CLASSVAR class labels for '$cols[0]' missing in meta data of $datasetType\n";
				next;
			}
			if($cols[1] eq $NULL_CLASS || $cols[2] eq $NULL_CLASS){
				die "Error: CLASSVAR class label equals NULL CLASS in $datasetType\n";
			}
			my $classVarName = uc($cols[0]);
			my $class1 = uc($cols[1]);
			my $class2 = uc($cols[2]);
			$classes{$classVarName} = {$class1 => 1, $class2 => 1};
		}
		if($row =~ /^#CLASSMEM/){
			my @cols = split(/\s+/, $row);
			shift(@cols);
			if(!$cols[0]){
				warn "Warning: CLASSMEM name missing in meta data of $datasetType\n";
				next;
			}
			my $classVarName = uc(shift(@cols));
			foreach my $class (@cols){
				$class = uc($class);
			}
			$membership{$classVarName} = \@cols;
		}
	}
	if(!$classes{$className} || !$membership{$className}){
		die "Error: Missing meta data for classification variable '$className' in $datasetType\n";
	}
	if(scalar(@{$membership{$className}}) != $totNumSamples){
		die "Error: CLASSMEM vector for '$className' and sample vector have different lengths in $datasetType\n";
	}
	foreach my $class (@{$membership{$className}}){
		if($class ne $NULL_CLASS && !$classes{$className}{$class}){
			die "Error: Invalid class label in '$className' CLASSMEM vector in $datasetType\n";
		}
	}
	my @classVector = @{$membership{$className}};
	my @classBuffer = sort(keys(%{$classes{$className}}));
	my $classOne = $classBuffer[0];
	my $classTwo = $classBuffer[1];
	
	#Determine what sample indexes to include
	my @includedInd;
	my $classOneCount = 0;
	my $classTwoCount = 0;
	for(my $sampleIndex = 0; $sampleIndex < $totNumSamples; $sampleIndex++){
		if($classVector[$sampleIndex] eq $classOne){
			$classOneCount++;
			push(@includedInd, $sampleIndex);
		}
		elsif($classVector[$sampleIndex] eq $classTwo){
			$classTwoCount++;
			push(@includedInd, $sampleIndex);
		}
	}
	if(!$classOneCount){
		die "Error: Class '$classOne' for classification variable '$className' has zero members in $datasetType\n";
	}
	if(!$classTwoCount){
		die "Error: Class '$classTwo' for classification variable '$className' has zero members in $datasetType\n";
	}
	my $numIncInd = scalar(@includedInd);
	
	#Check for sample duplicates
	for(my $outer = 0; $outer < $totNumSamples - 1; $outer++){
		for(my $inner = $outer + 1; $inner < $totNumSamples; $inner++){
			if($samples[$outer] eq $samples[$inner]){
				warn "Warning: Duplicate sample name '$samples[$outer]' at positions ", $outer + 1, " and ", $inner + 1, " in $datasetType\n";
			}
		}
	}
	
	#Initialise Algorithm::TrunkClassifier::DataWrapper object
	my @incSampleNames;
	my @incClassVector;
	my @probeNames;
	my @dataMatrix;
	foreach my $index (@includedInd){
		push(@incSampleNames, $samples[$index]);
		push(@incClassVector, $classVector[$index]);
	}
	for(my $rowIndex = 0; $rowIndex < scalar(@dataFile); $rowIndex++){
		$dataFile[$rowIndex] =~ s/,/./g;
		my @cols = split(/\t/, $dataFile[$rowIndex]);
		if(scalar(@cols) != $totNumSamples + 1){
			die "Error: Wrong number of columns in $datasetType at probe ", $rowIndex + 1, "\n";
		}
		my $probe = "$rowIndex:" . shift(@cols);
		push(@probeNames, $probe);
		my @includedCols;
		foreach my $index (@includedInd){
			$cols[$index] =~ s/\s+//g;
			if($cols[$index] !~ /^-?[0-9]+(\.[0-9]+)?([Ee][+\-]?[0-9]+)?$/){
				warn "Warning: Missing/invalid value '$cols[$index]' in $datasetType at probe ", $rowIndex + 1, "\n";
				$cols[$index] =~ s/[^0-9]+//g;
			}
			if($cols[$index] !~ /\./){
				$cols[$index] .= ".0";
			}
			push(@includedCols, $cols[$index] + 0);
		}
		push(@dataMatrix, \@includedCols);
	}
	
	#Check prospect flag
	if($prospect){
		if($prospect eq $PROSPECT_SAMPLES){
			die "Number of samples with $className class\n$classOne: $classOneCount\n$classTwo: $classTwoCount\n";
		}
		elsif($prospect eq $PROSPECT_PROBES){
			my $numProbes = scalar(@dataMatrix);
			die "Number of probes in dataset: $numProbes\n";
		}
		elsif($prospect eq $PROSPECT_CLASSES){
			my @classKeys = keys(%classes);
			die "Classes in the dataset: @classKeys\n";
		}
	}
	$self->{"colnames"} = \@incSampleNames;
	$self->{"rownames"} = \@probeNames;
	$self->{"data_matrix"} = \@dataMatrix;
	$self->{"class_vector"} = \@incClassVector;
	$self->{"class_one"} = $classOne;
	$self->{"class_two"} = $classTwo;
}

#Description: Returns the number of samples in the dataset
#Parameters: (1) TrunkClassifier::DataWrapper object
#Return value: Number of elements in "colnames" attribute
sub getNumSamples($){
	my $self = shift(@_);
	return scalar(@{$self->{"colnames"}});
}

#Description: Returns the number of probes in the dataset
#Parameters: (1) TrunkClassifier::DataWrapper object
#Return value: Number of rows in "rownames" array
sub getNumProbes($){
	my $self = shift(@_);
	return scalar(@{$self->{"rownames"}});
}

#Description: Returns the row names of the DataWrapper object
#Parameters: (1) TrunkClassifier::DataWrapper object
#Return value: Array of row names
sub getProbeList($){
	my $self = shift(@_);
	return @{$self->{"rownames"}};
}

#Description: Returns a reference to the data matrix
#Parameters: (1) TrunkClassifier::DataWrapper object
#Return value: Array reference
sub getDataMatrix($){
	my $self = shift(@_);
	return $self->{"data_matrix"};
}

#Description: Returns a reference to the class vector
#Parameters: (1) TrunkClassifier::DataWrapper object
#Return value: Array reference
sub getClassVector($){
	my $self = shift(@_);
	return $self->{"class_vector"};
}

#Description: Returns the name of class one
#Parameters: (1) TrunkClassifier::DataWrapper object
#Return value: Class name
sub getClassOneName($){
	my $self = shift(@_);
	return $self->{"class_one"};
}

#Description: Returns the name of class two
#Parameters: (1) TrunkClassifier::DataWrapper object
#Return value: Class name
sub getClassTwoName($){
	my $self = shift(@_);
	return $self->{"class_two"};
}

#Description: Returns a copy of a TrunkClassifier::DataWrapper object
#Parameters: (1) TrunkClassifier::DataWrapper object
#Return value: New TrunkClassifier::DataWrapper object
sub copy($){
	my $self = shift(@_);
	my $newWrapper = Algorithm::TrunkClassifier::DataWrapper->new();
	my @colnames = @{$self->{"colnames"}};
	my @rownames = @{$self->{"rownames"}};
	my @classVector = @{$self->{"class_vector"}};
	my @dataMatrix;
	foreach my $arrayRef (@{$self->{"data_matrix"}}){
		my @arrayCopy = @{$arrayRef};
		push(@dataMatrix, \@arrayCopy);
	}
	$newWrapper->{"colnames"} = \@colnames;
	$newWrapper->{"rownames"} = \@rownames;
	$newWrapper->{"data_matrix"} = \@dataMatrix;
	$newWrapper->{"class_vector"} = \@classVector;
	$newWrapper->{"class_one"} = $self->{"class_one"};
	$newWrapper->{"class_two"} = $self->{"class_two"};
	return $newWrapper;
}

#Description: Removes one sample from a TrunkClassifier::DataWrapper object
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) index of sample to remove
#Return value: TrunkClassifier::DataWrapper object containing the removed sample
sub leaveOneOut($ $){
	my ($self, $index) = @_;
	my @colnames = ($self->{"colnames"}[$index]);
	my @rownames = @{$self->{"rownames"}};
	my @classVector = ($self->{"class_vector"}[$index]);
	my @matrixCol;
	for(my $row = 0; $row < scalar(@rownames); $row++){
		my @colArray = splice(@{$self->{"data_matrix"}[$row]}, $index, 1);
		push(@matrixCol, \@colArray);
	}
	splice(@{$self->{"colnames"}}, $index, 1);
	splice(@{$self->{"class_vector"}}, $index, 1);
	my $newWrapper = Algorithm::TrunkClassifier::DataWrapper->new();
	$newWrapper->{"colnames"} = \@colnames;
	$newWrapper->{"rownames"} = \@rownames;
	$newWrapper->{"data_matrix"} = \@matrixCol;
	$newWrapper->{"class_vector"} = \@classVector;
	$newWrapper->{"class_one"} = $self->{"class_one"};
	$newWrapper->{"class_two"} = $self->{"class_two"};
	return $newWrapper;
}

#Description: Removes a percentage of samples from a TrunkClassifier::DataWrapper object
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) split percent
#Return value: TrunkClassifier::DataWrapper object containing the removed samples
sub splitSamples($ $){
	my ($self, $split) = @_;
	my $totNumSamples = $self->getNumSamples();
	my $testSetSize = floor(($split / 100) * $totNumSamples);
	my @colnames;
	my @rownames = $self->getProbeList();
	my @classVector;
	my @matrix;
	for(my $row = 0; $row < $self->getNumProbes(); $row++){
		my @array;
		push(@matrix, \@array);
	}
	for(my $testIndex = 0; $testIndex < $testSetSize; $testIndex++){
		my $randIndex = int(rand($self->getNumSamples()));
		my $colname = splice(@{$self->{"colnames"}}, $randIndex, 1);
		push(@colnames, $colname);
		my $class = splice(@{$self->{"class_vector"}}, $randIndex, 1);
		push(@classVector, $class);
		for(my $row = 0; $row < $self->getNumProbes(); $row++){
			my $value = splice(@{$self->{"data_matrix"}[$row]}, $randIndex, 1);
			push(@{$matrix[$row]}, $value);
		}
	}
	my $testSet = Algorithm::TrunkClassifier::DataWrapper->new();
	$testSet->{"colnames"} = \@colnames;
	$testSet->{"rownames"} = \@rownames;
	$testSet->{"data_matrix"} = \@matrix;
	$testSet->{"class_vector"} = \@classVector;
	$testSet->{"class_one"} = $self->{"class_one"};
	$testSet->{"class_two"} = $self->{"class_two"};
	return $testSet;
}

#Description: Returns the number of samples in the specified class
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) class
#Return value: Array with column indexes
sub getClassSize($ $){
	my ($self, $class) = @_;
	my $classSize = 0;
	foreach my $sampleClass (@{$self->{"class_vector"}}){
		if($sampleClass eq $class){
			$classSize++;
		}
	}
	return $classSize;
}

#Description: Returns the probe name of the probe row index given as argument
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) probe row index
#Return value: Probe name
sub getProbeName($ $){
	my ($self, $probeIndex) = @_;
	return ${$self->{"rownames"}}[$probeIndex];
}

#Description: Returns the probe row index of the probe name given as argument
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) probe name
#Return value: Probe row index
sub getProbeIndex($ $){
	my ($self, $probeName) = @_;
	for(my $probeIndex = 0; $probeIndex < $self->getNumProbes(); $probeIndex++){
		if($self->{"rownames"}[$probeIndex] eq $probeName){
			return $probeIndex;
		}
	}
	return undef;
}

#Description: Returns the data matrix row corresponding to the argument index
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) row index
#Return value: Array
sub getMatrixRow($ $){
	my ($self, $rowIndex) = @_;
	return @{$self->{"data_matrix"}[$rowIndex]};
}

#Description: Returns the sample name corresponding to the sample index given
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) sample index
#Return value: Array reference
sub getSampleName($ $){
	my ($self, $sampleIndex) = @_;
	return $self->{"colnames"}[$sampleIndex];
}

#Description: Removes a probe name from row names and its row from the data matrix
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) probe index
#Return value: None
sub removeProbe($ $){
	my ($self, $probeIndex) = @_;
	splice(@{$self->{"rownames"}}, $probeIndex, 1);
	splice(@{$self->{"data_matrix"}}, $probeIndex, 1);
}

#Description: Removes a sample name from col names, its class from class vector, and its column from the data matrix
#Parameters: (1) TrunkClassifier::DataWrapper object, (2) sample index
#Return value: None
sub removeSample($ $){
	my ($self, $sampleIndex) = @_;
	splice(@{$self->{"colnames"}}, $sampleIndex, 1);
	splice(@{$self->{"class_vector"}}, $sampleIndex, 1);
	foreach my $rowref (@{$self->{"data_matrix"}}){
		splice(@{$rowref}, $sampleIndex, 1);
	}
}

return 1;
