use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 	'Data::Validate',
    'VERSION_FROM' 	=> 	'Validate.pm', # finds $VERSION
    'DISTNAME'		=>	'Data-Validate',
    'AUTHOR'		=>	'Richard Sonnen (sonnen@richardsonnen.com)',
    'PREREQ_PM'		=>	{
    					'POSIX'		=>	0,
					'Math::BigInt'	=>	1.77,
    					},
    'dist'			=>	{
    					'COMPRESS'	=>	'gzip -9f',
    					'SUFFIX'	=>	'gz',
    					'ZIP'		=>	'/usr/bin/zip',
    					'ZIPFLAGS'	=>	'-rl',
    					},
);
