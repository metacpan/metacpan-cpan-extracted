use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Phrasebook',
    'VERSION_FROM'	=> 'Phrasebook.pm', # finds $VERSION
    'PREREQ_PM'		=> { Log::LogLite => 0.2,
	                     IO::LockedFile => 0.1,
	                     Term::ANSIColor => 1.03,
	                     XML::Parser => 2.30 }, 
);
