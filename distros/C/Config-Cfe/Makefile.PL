use ExtUtils::MakeMaker;

# $Revision: 1.6 $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Config::Cfe',
    'VERSION_FROM'	=> 'Cfe.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'clean'		=> {FILES => "testdata"},
    'EXE_FILES'		=> ['update-cfe'],
);
