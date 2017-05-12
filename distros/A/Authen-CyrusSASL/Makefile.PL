use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Authen::CyrusSASL',
    'VERSION_FROM' 	=> 'Authen/CyrusSASL.pm', # finds $VERSION
	'PREREQ_PM' 	=> { IO => 1.12 },
	'dist'		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

