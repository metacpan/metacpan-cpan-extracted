package Algorithm::TrunkClassifier::CommandProcessor;

use warnings;
use strict;

our $VERSION = 'v1.0.1';

my %commands;

#Description: Command processor constructor
#Parameters: (1) TrunkClassifier::CommandProcessor, (2) classification procedure ref, (3), split ref, (4) testset ref,
#            (5) class name variable ref, (6) output folder variable ref, (7) level variable ref, (8) prospect variable ref,
#            (9) supplementary file variable ref, (10) verbose variable ref, (11) useall variable ref, (12) input data file variable ref
#Return value: TrunkClassifier::CommandProcessor object
sub new($ $ $ $ $ $ $ $ $ $ $ $ $){
	my ($class, $classifyRef, $splitPercentRef, $testsetRef, $classnameRef, $outputRef, $levelRef, $prospectRef, $suppfileRef, $verboseRef, $useallRef, $datafileRef) = @_;
	%commands = (
		"-p"			=> {"numArgs" => 1, "validArgs" => 'loocv|split|dual', "var" => $classifyRef, "sub" => \&checkTestsetArg},
		"--procedure"	=> {"numArgs" => 1, "validArgs" => 'loocv|split|dual', "var" => $classifyRef},
		"-e"            => {"numArgs" => 1, "validArgs" => '^[1-9][0-9]?$', "var" => $splitPercentRef},
		"--split"       => {"numArgs" => 1, "validArgs" => '^[1-9][0-9]?$', "var" => $splitPercentRef},
		"-t"			=> {"numArgs" => 1, "validArgs" => '.+', "var" => $testsetRef},
		"--testset"		=> {"numArgs" => 1, "validArgs" => '.+', "var" => $testsetRef},
		"-c"			=> {"numArgs" => 1, "validArgs" => '.+', "var" => $classnameRef},
		"--classvar"	=> {"numArgs" => 1, "validArgs" => '.+', "var" => $classnameRef},
		"-o"			=> {"numArgs" => 1, "validArgs" => '.+', "var" => $outputRef},
		"--output"		=> {"numArgs" => 1, "validArgs" => '.+', "var" => $outputRef},
		"-l"			=> {"numArgs" => 1, "validArgs" => '^[1-5]+$', "var" => $levelRef},
		"--levels"		=> {"numArgs" => 1, "validArgs" => '^[1-5]+$', "var" => $levelRef},
		"-i"			=> {"numArgs" => 1, "validArgs" => '^samples|probes|classes$', "var" => $prospectRef},
		"--inspect"		=> {"numArgs" => 1, "validArgs" => '^samples|probes|classes$', "var" => $prospectRef},
		"-s"			=> {"numArgs" => 1, "validArgs" => '.+', "var" => $suppfileRef},
		"--supp"		=> {"numArgs" => 1, "validArgs" => '.+', "var" => $suppfileRef},
		"-v"			=> {"numArgs" => 0, "var" => $verboseRef, "value" => 1},
		"--verbose"		=> {"numArgs" => 0, "var" => $verboseRef, "value" => 1},
		"-u"			=> {"numArgs" => 0, "var" => $useallRef, "value" => 1},
		"--useall"		=> {"numArgs" => 0, "var" => $useallRef, "value" => 1},
		"-h"			=> {"numArgs" => 0, "sub" => \&commandHelp},
		"--help"		=> {"numArgs" => 0, "sub" => \&commandHelp}
	);
	my $self = {"input" => $datafileRef};
	bless($self, $class);
	return $self;
}

#Description: Command processor loop
#Parameters: Command line arguments
#Return value: None
sub processCmd{
	my $self = shift(@_);
	my @commandLine = @_;
	my @allCommands = @_;
	if(!@commandLine){
		commandHelp();
	}
	while(@commandLine){
		my $com = shift(@commandLine);
		my $arg;
		if(!$commands{$com}){
			if(scalar(@commandLine) >= 1){
				die "Error: Unrecognized command '$com'\n";
			}
			${$self->{"input"}} = $com;
			return;
		}
		if($commands{$com}{"numArgs"} == 1){
			$arg = shift(@commandLine);
			if($arg =~ /^-/){
				die "Error: Missing argument for command $com\n";
			}
			my $valid = $commands{$com}{"validArgs"};
			if($arg !~ /$valid/){
				die "Error: Invalid argument '$arg' to $com\n";
			}
		}
		if($commands{$com}{"var"}){
			if($commands{$com}{"value"}){
				${$commands{$com}{"var"}} = $commands{$com}{"value"};
			}
			else{
				${$commands{$com}{"var"}} = $arg;
			}
		}
		if($commands{$com}{"sub"}){
			&{$commands{$com}{"sub"}}($arg, \@allCommands);
		}
	}
	if(!${$self->{"input"}}){
		die "Error: Input data file not supplied\n";
	}
}

#Description: Checks that the -t option is supplied if -c dual is used
#Parameters: (1) The -c argument, (2) command line arguments
#Return value: None
sub checkTestsetArg($ $){
	my ($argument, $comLineRef) = @_;
	if($argument eq "dual"){
		my $foundT = 0;
		foreach my $arg (@{$comLineRef}){
			if($arg eq "-t"){
				$foundT = 1;
				last;
			}
		}
		if(!$foundT){
			die "Error: Command line option -t must be given when -c dual is used\n";
		}
	}
}

#Description: Command line help
#Parameters: None
#Return value: None
sub commandHelp(){
	my $doc = <<END;
Usage
    perl trunk_classifier.pl [Options] [File]

Options
	-p, --procedure     Classification procedure to use [loocv|split|dual]
	-e, --split         Percentage of samples to use as test set when using -p split
	-t, --testset       Dataset to classify when using -c dual
    -c, --classvar      Name of the classification variable to use
    -o, --output        Name of the output folder
    -l, --levels        Force classifier to use trunks with X levels for classification
    -i, --inspect       Check data file before running [samples|probes|classes]
    -s, --supp          Supplementary file containing class information
    -v, --verbose       Report progress during classifier run
    -u, --useall        Circumvent level selection and use all trunks for classification
    -h, --help          Print command line help

Output
    performance:   Classification accuracy for each LOOCV fold, as well as average accuracy
    loo_trunks:    Structures of leave-one-out decision trunks
    cts_trunks:    Structure of trunks built with compete training set
    class_report:  Classification of all test samples
    log:           Arguments used
END
	die $doc;
}

return 1;
