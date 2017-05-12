use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ClearCase::Attache',
    'VERSION_FROM'	=> 'Attache.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Win32  => '0.0',
	Symbol => '0.0',
    }, # e.g., Module::Name => 1.1
);
