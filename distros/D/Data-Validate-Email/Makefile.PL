use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 	'Data::Validate::Email',
    'VERSION_FROM' 	=> 	'Email.pm', # finds $VERSION
    'DISTNAME'		=>	'Data-Validate-Email',
    'AUTHOR'		=>	'Richard Sonnen (sonnen@richardsonnen.com)',
    'PREREQ_PM'		=>	{
    				'Email::Address'			=>	0,
    				'Data::Validate::Domain'	=>	0.04,
    				},
    'dist'		=>	{
    				'COMPRESS'	=>	'gzip -9f',
    				'SUFFIX'	=>	'gz',
    				'ZIP'		=>	'/usr/bin/zip',
    				'ZIPFLAGS'	=>	'-rl',
    				},
);
