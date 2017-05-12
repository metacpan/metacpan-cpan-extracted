use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    AUTHOR	=> 'Charles C. Fu (perl@web-i18n.net)',
    NAME	=> 'Apache::Gateway',
    VERSION	=> '1.11',
    dist	=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
    PREREQ_PM	=> {
    	'Apache::Constants'	=> '0',
    }
);
