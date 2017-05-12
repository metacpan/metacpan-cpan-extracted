package Algorithm::TrunkClassifier;

use 5.010000;
use warnings;
use strict;

use Algorithm::TrunkClassifier::CommandProcessor;
use Algorithm::TrunkClassifier::DataWrapper;
use Algorithm::TrunkClassifier::Classification;
require Exporter;

our $VERSION = 'v1.0.1';

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	runClassifier
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#Classifier arguments
my $CLASSIFY = "loocv";		#Classification procedure (loocv|split|dual)
my $SPLITPERCENT = 20;		#Percentage of samples to use as test set when using -c split
my $TESTSET = "";			#Name of test dataset when using -c dual
my $CLASSNAME = "TISSUE";	#Name of classification variable
my $OUTPUT = ".";			#Name of output folder
my $LEVELS = 0;				#Number of levels in decision trunks (forced)
my $PROSPECT = "";			#Check input data without running classifier
my $SUPPFILE = "";			#File containing class information
my $VERBOSE = 0;			#Report progress during classifier run
my $USEALL = 0;				#Circumvent level selection and use all trunks for classification
my $DATAFILE = "";			#File containing input data

#Description: Wrapper function for running the decision trunk classifier
#Parameters: Command line arguments
#Return value: None
sub runClassifier{
	#Handle commands line arguments
	my $processor = Algorithm::TrunkClassifier::CommandProcessor->new(\$CLASSIFY, \$SPLITPERCENT, \$TESTSET, \$CLASSNAME, \$OUTPUT, \$LEVELS, \$PROSPECT, \$SUPPFILE, \$VERBOSE, \$USEALL, \$DATAFILE);
	$processor->processCmd(@_);
	
	#Read input data
	if($VERBOSE){
		print("Trunk classifier: Reading input data\n");
	}
	my $dataWrapper = Algorithm::TrunkClassifier::DataWrapper->new($CLASSNAME, $PROSPECT, $SUPPFILE, $DATAFILE, $VERBOSE, "input data file");
	my $testset;
	if($CLASSIFY eq "dual"){
		$testset = Algorithm::TrunkClassifier::DataWrapper->new($CLASSNAME, $PROSPECT, $SUPPFILE, $TESTSET, $VERBOSE, "testset data file");
		if($VERBOSE){
			print("Trunk classifier: Two datasets used, checking probe overlap\n");
		}
		my @probeSet1 = $dataWrapper->getProbeList();
		my @probeSet2 = $testset->getProbeList();
		foreach my $query (@probeSet1){
			my $found = 0;
			foreach my $probe (@probeSet2){
				if($query eq $probe){
					$found = 1;
					last;
				}
			}
			if(!$found){
				die "Error: Probe '$query' in input data file not found in testset data file\n";
			}
		}
	}
	
	#Run cross validation loop
	Algorithm::TrunkClassifier::Classification->trainAndClassify($dataWrapper, $testset, $CLASSIFY, $SPLITPERCENT, $TESTSET, $CLASSNAME, $OUTPUT, $LEVELS, $VERBOSE, $DATAFILE, $USEALL);
}

return 1;
