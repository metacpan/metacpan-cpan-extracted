use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 	'Data::Validate::URI',
    'VERSION_FROM' 	=> 	'lib/Data/Validate/URI.pm', # finds $VERSION
    'DISTNAME'		=>	'Data-Validate-URI',
    'AUTHOR'		=>	'Richard Sonnen (sonnen@richardsonnen.com)',
    'PREREQ_PM'		=>	{
    				'Data::Validate::Domain'	=>	0,
    				'Data::Validate::IP'	=>	0,
    				},
    'dist'		=>	{
    				'COMPRESS'	=>	'gzip -9f',
    				'SUFFIX'	=>	'gz',
    				'ZIP'		=>	'/usr/bin/zip',
    				'ZIPFLAGS'	=>	'-rl',
    				},
);
