# Makefile.PL for installing Algorithm::SISort by
# Hrafnkell Freyr Hlodversson.
# Please report bugs to keli@panmedia.dk or on
# http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-SISort

use strict;

my %MakefileParameters = (
    'AUTHOR'            => 'Hrafnkell Freyr Hlodversson',
    'NAME'		=> 'Algorithm::SISort',
    'VERSION_FROM'	=> 'SISort.pm', # finds $VERSION
    'PREREQ_PM'		=> {Inline => '0.40'}, 
);


# First try using Inline::MakeMaker
eval q{
	use Inline::MakeMaker;
};

# Make sure to give the correct warning when Inline::Makemaker is
# not available (ie. Inline is not installed, or less than
# version 0.40):
eval {
	print STDERR "Warning: Could not load Inline::MakeMaker. ".
                     "Falling back to ExtUtils::MakeMaker\n";
	use ExtUtils::MakeMaker;
} if $@;

WriteMakefile(%MakefileParameters);
