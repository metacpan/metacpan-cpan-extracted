# Perl version checking
eval {require 5.6.0} or die <<'EOD';
* This module uses functions which are only available in perls
* greater than 5.6.0 which you do not seem to have yet.
EOD

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'AI::Gene::Sequence',
    'VERSION_FROM'	=> 'AI/Gene/Sequence.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'PL_FILES'          => {}, # some demos included, do not need to be run
    'PM'                => { 'AI/Gene/Sequence.pm'
			     => '$(INST_LIBDIR)/Sequence.pm',
			     'AI/Gene/Simple.pm'
			     => '$(INST_LIBDIR)/Simple.pm'},
);
